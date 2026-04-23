-- Create the state enum
CREATE TYPE item_state AS ENUM ('clean', 'worn', 'laundry');

-- Create the items table
CREATE TABLE public.items (
    item_id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
    image_url TEXT NOT NULL,
    ml_detected_category TEXT,
    category TEXT NOT NULL,
    primary_hex TEXT NOT NULL,
    warmth_clo NUMERIC NOT NULL DEFAULT 0.0,
    purchase_price NUMERIC,
    occasions TEXT[] DEFAULT '{}',
    fabrics TEXT[] DEFAULT '{}',
    times_worn INTEGER NOT NULL DEFAULT 0,
    state item_state NOT NULL DEFAULT 'clean',
    wears_before_laundry INTEGER NOT NULL DEFAULT 1,
    last_worn_at TIMESTAMP WITH TIME ZONE,
    -- Auto-calculate cost_per_wear. If never worn (0), it equals purchase_price.
    cost_per_wear NUMERIC GENERATED ALWAYS AS (
        COALESCE(purchase_price / NULLIF(times_worn, 0), purchase_price)
    ) STORED
);

-- Turn on Row Level Security
ALTER TABLE public.items ENABLE ROW LEVEL SECURITY;

-- 1. SELECT Policy
CREATE POLICY "Users can view their own items" 
ON public.items FOR SELECT 
USING (auth.uid() = user_id);

-- 2. INSERT Policy
CREATE POLICY "Users can insert their own items" 
ON public.items FOR INSERT 
WITH CHECK (auth.uid() = user_id);

-- 3. UPDATE Policy
CREATE POLICY "Users can update their own items" 
ON public.items FOR UPDATE 
USING (auth.uid() = user_id)
WITH CHECK (auth.uid() = user_id);

-- 4. DELETE Policy
CREATE POLICY "Users can delete their own items" 
ON public.items FOR DELETE 
USING (auth.uid() = user_id);

-- Create a storage bucket for the items
INSERT INTO storage.buckets (id, name, public) VALUES ('wardrobe', 'wardrobe', false);

-- Storage Policies for 'wardrobe' bucket
CREATE POLICY "Users can upload item images"
ON storage.objects FOR INSERT
WITH CHECK (
    bucket_id = 'wardrobe' AND 
    auth.uid()::text = (storage.foldername(name))[1]
);

CREATE POLICY "Users can update their item images"
ON storage.objects FOR UPDATE
USING (
    bucket_id = 'wardrobe' AND 
    auth.uid()::text = (storage.foldername(name))[1]
);

CREATE POLICY "Users can view their item images"
ON storage.objects FOR SELECT
USING (
    bucket_id = 'wardrobe' AND 
    auth.uid()::text = (storage.foldername(name))[1]
);

CREATE POLICY "Users can delete their item images"
ON storage.objects FOR DELETE
USING (
    bucket_id = 'wardrobe' AND 
    auth.uid()::text = (storage.foldername(name))[1]
);
