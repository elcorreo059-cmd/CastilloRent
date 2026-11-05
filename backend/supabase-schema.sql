-- ============================================================================
-- CASTILLO RENT CAR ERP v3.2.2 — ESQUEMA SUPABASE + BLINDAJE RLS
-- ============================================================================

CREATE TABLE IF NOT EXISTS public.erp_state (
  id TEXT PRIMARY KEY DEFAULT 'main',
  data JSONB NOT NULL DEFAULT '{}'::jsonb,
  version INTEGER NOT NULL DEFAULT 1,
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_by TEXT DEFAULT ''
);

ALTER TABLE public.erp_state
  DROP CONSTRAINT IF EXISTS erp_state_only_main,
  ADD CONSTRAINT erp_state_only_main CHECK (id = 'main');

ALTER TABLE public.erp_state ENABLE ROW LEVEL SECURITY;

CREATE OR REPLACE FUNCTION public.current_erp_role()
RETURNS TEXT
LANGUAGE sql
STABLE
AS $$
  SELECT COALESCE(
    auth.jwt() -> 'app_metadata' ->> 'erp_role',
    ''
  );
$$;

DROP POLICY IF EXISTS "Lectura autorizada ERP" ON public.erp_state;
CREATE POLICY "Lectura autorizada ERP"
  ON public.erp_state
  FOR SELECT
  TO authenticated
  USING (public.current_erp_role() IN ('admin', 'operator'));

DROP POLICY IF EXISTS "Insercion inicial autorizada ERP" ON public.erp_state;
CREATE POLICY "Insercion inicial autorizada ERP"
  ON public.erp_state
  FOR INSERT
  TO authenticated
  WITH CHECK (
    id = 'main' AND public.current_erp_role() IN ('admin', 'operator')
  );

DROP POLICY IF EXISTS "Actualizacion autorizada ERP" ON public.erp_state;
CREATE POLICY "Actualizacion autorizada ERP"
  ON public.erp_state
  FOR UPDATE
  TO authenticated
  USING (public.current_erp_role() IN ('admin', 'operator'))
  WITH CHECK (
    id = 'main' AND public.current_erp_role() IN ('admin', 'operator')
  );

DROP POLICY IF EXISTS "Prohibir borrado de estado" ON public.erp_state;
CREATE POLICY "Prohibir borrado de estado"
  ON public.erp_state
  FOR DELETE
  TO authenticated
  USING (false);
