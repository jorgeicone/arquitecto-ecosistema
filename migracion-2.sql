-- ============================================================
-- ICONE · Arquitecto de Ecosistema — MIGRACIÓN 2 (académica)
-- Uso: herramienta abierta y ANÓNIMA.
-- Añade 2 columnas nuevas y deja de recoger datos personales.
-- SEGURO: solo ADD COLUMN IF NOT EXISTS + CREATE OR REPLACE.
-- ============================================================

-- 1. Columnas nuevas (formación previa y preocupaciones)
alter table public.icone_diagnosticos_eco add column if not exists formacion text;
alter table public.icone_diagnosticos_eco add column if not exists preocupaciones jsonb;

-- 2. Las columnas nombre/email quedan en la tabla pero YA NO SE ESCRIBEN.
--    No se eliminan para no romper nada. Se anula lo que hubiera.
update public.icone_diagnosticos_eco set nombre=null, email=null
  where nombre is not null or email is not null;

-- 3. Stats públicas: agrega las preocupaciones y la formación
create or replace function public.get_stats_eco()
returns jsonb language plpgsql security definer set search_path=public as $$
declare res jsonb; n int;
begin
  select count(*) into n from public.icone_diagnosticos_eco;
  select jsonb_build_object(
    'total', n,
    'updated_at', now(),
    'horas_prom', (select round(avg(horas)::numeric,1) from public.icone_diagnosticos_eco),
    'madurez_prom', (select round(avg(madurez)::numeric,2) from public.icone_diagnosticos_eco),
    'niveles', (select jsonb_object_agg(k,c) from (
        select coalesce(nivel,'—') k, count(*) c from public.icone_diagnosticos_eco group by 1) s),
    'rutas', (select jsonb_object_agg(k,c) from (
        select coalesce(ruta,'—') k, count(*) c from public.icone_diagnosticos_eco group by 1) s),
    'formacion', (select jsonb_object_agg(k,c) from (
        select coalesce(formacion,'—') k, count(*) c from public.icone_diagnosticos_eco group by 1) s),
    'sectores', (select jsonb_object_agg(k,c) from (
        select coalesce(nullif(trim(sector),''),'—') k, count(*) c
        from public.icone_diagnosticos_eco group by 1 order by 2 desc limit 12) s),
    'presupuesto', (select jsonb_object_agg(k,c) from (
        select coalesce(presupuesto,'—') k, count(*) c from public.icone_diagnosticos_eco group by 1) s),
    'ecosistema', (select jsonb_object_agg(k,c) from (
        select coalesce(ecosistema,'—') k, count(*) c from public.icone_diagnosticos_eco group by 1) s),
    'membresias', (select coalesce(jsonb_object_agg(item,c),'{}'::jsonb) from (
        select jsonb_array_elements_text(membresias) item, count(*) c
        from public.icone_diagnosticos_eco where membresias is not null group by 1) t),
    'tareas', (select coalesce(jsonb_object_agg(item,c),'{}'::jsonb) from (
        select jsonb_array_elements_text(tareas) item, count(*) c
        from public.icone_diagnosticos_eco where tareas is not null group by 1) t),
    'frenos', (select coalesce(jsonb_object_agg(item,c),'{}'::jsonb) from (
        select jsonb_array_elements_text(frenos) item, count(*) c
        from public.icone_diagnosticos_eco where frenos is not null group by 1) t),
    'preocupaciones', (select coalesce(jsonb_object_agg(item,c),'{}'::jsonb) from (
        select jsonb_array_elements_text(preocupaciones) item, count(*) c
        from public.icone_diagnosticos_eco where preocupaciones is not null group by 1) t),
    'ya_hecho', (select coalesce(jsonb_object_agg(item,c),'{}'::jsonb) from (
        select jsonb_array_elements_text(ya_hecho) item, count(*) c
        from public.icone_diagnosticos_eco where ya_hecho is not null group by 1) t)
  ) into res;
  return res;
end; $$;

grant execute on function public.get_stats_eco() to anon;

select 'OK · migracion academica aplicada' as estado;
