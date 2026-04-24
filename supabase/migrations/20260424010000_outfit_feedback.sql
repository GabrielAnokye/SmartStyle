-- Phase 5 slice 2: thumbs-down feedback on recommended outfits.
-- The engine reads recent rows (last 14 days) and penalizes outfits that
-- share items with a downvoted one. Thumbs-up is implicit via wear_events,
-- so this table only stores negative signal.

CREATE TABLE public.outfit_feedback (
    feedback_id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    item_ids UUID[] NOT NULL,
    -- Free-text category ('too_warm' | 'too_formal' | 'clash' | 'other').
    -- Kept as text, not an enum, so adding reasons later is just an app update.
    reason TEXT,
    -- Hash of the context snapshot for future "why did we rec this" analysis.
    context_hash TEXT,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT timezone('utc', now())
);

CREATE INDEX outfit_feedback_user_created_idx
    ON public.outfit_feedback (user_id, created_at DESC);

ALTER TABLE public.outfit_feedback ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view their own feedback"
    ON public.outfit_feedback FOR SELECT
    USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own feedback"
    ON public.outfit_feedback FOR INSERT
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can delete their own feedback"
    ON public.outfit_feedback FOR DELETE
    USING (auth.uid() = user_id);
