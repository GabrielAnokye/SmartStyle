-- Phase 5: wear events are the single source of truth for "has this been worn."
-- Inserting a row here drives:
--   items.times_worn += 1
--   items.last_worn_at = worn_at
--   items.state transitions clean -> worn -> laundry based on wears_before_laundry.
-- Clients never update those columns directly.

CREATE TABLE public.wear_events (
    event_id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    item_id UUID NOT NULL REFERENCES public.items(item_id) ON DELETE CASCADE,
    -- Nullable so manual "I wore X yesterday" entries can set a backdated time.
    worn_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT timezone('utc', now()),
    -- Optional: lets us group items that were logged together for "recent outfits".
    outfit_key TEXT,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT timezone('utc', now())
);

CREATE INDEX wear_events_user_id_worn_at_idx
    ON public.wear_events (user_id, worn_at DESC);
CREATE INDEX wear_events_item_id_idx
    ON public.wear_events (item_id);

ALTER TABLE public.wear_events ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view their own wear events"
    ON public.wear_events FOR SELECT
    USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own wear events"
    ON public.wear_events FOR INSERT
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can delete their own wear events"
    ON public.wear_events FOR DELETE
    USING (auth.uid() = user_id);

-- Trigger function: after a wear event, advance the item's counters + state.
-- SECURITY DEFINER so it can bypass RLS when updating items (RLS is still
-- enforced on the INSERT into wear_events itself).
CREATE OR REPLACE FUNCTION public.fn_apply_wear_event()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_wears_before_laundry INTEGER;
    v_new_times_worn INTEGER;
    v_current_state item_state;
BEGIN
    -- Look up the item and own-check.
    SELECT wears_before_laundry, state
      INTO v_wears_before_laundry, v_current_state
      FROM public.items
     WHERE item_id = NEW.item_id
       AND user_id = NEW.user_id;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Item % does not belong to user %', NEW.item_id, NEW.user_id;
    END IF;

    v_new_times_worn := (
        SELECT times_worn + 1 FROM public.items WHERE item_id = NEW.item_id
    );

    UPDATE public.items
       SET times_worn = v_new_times_worn,
           last_worn_at = NEW.worn_at,
           -- Already-in-laundry items stay in laundry (weird edge case — user
           -- explicitly logged a wear after marking dirty; we don't second-guess).
           state = CASE
               WHEN state = 'laundry' THEN 'laundry'::item_state
               WHEN v_new_times_worn % GREATEST(v_wears_before_laundry, 1) = 0
                   THEN 'laundry'::item_state
               ELSE 'worn'::item_state
           END
     WHERE item_id = NEW.item_id;

    RETURN NEW;
END;
$$;

CREATE TRIGGER trg_apply_wear_event
    AFTER INSERT ON public.wear_events
    FOR EACH ROW
    EXECUTE FUNCTION public.fn_apply_wear_event();
