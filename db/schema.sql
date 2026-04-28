-- ============================================================
-- QTTB DSS — Database Schema
-- Platform: Supabase (PostgreSQL)
-- Run this in Supabase SQL Editor: app.supabase.com → SQL Editor
-- ============================================================

-- ── SOIL SURVEYS ────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS soil_surveys (
  id              BIGSERIAL PRIMARY KEY,
  created_at      TIMESTAMPTZ DEFAULT NOW(),
  updated_at      TIMESTAMPTZ DEFAULT NOW(),

  -- Site identification
  ref_no          TEXT,
  commune         TEXT,
  district        TEXT,
  survey_date     DATE,
  surveyor        TEXT,
  gps_e           NUMERIC(12,6),
  gps_n           NUMERIC(12,6),
  qttb_area       TEXT,  -- 'korce_apple' | 'lushnje_tomato' | 'vlore_olive'

  -- Topography
  slope_pct       NUMERIC(5,2),
  slope_class     SMALLINT,
  landform        SMALLINT,
  landform_class  TEXT,

  -- Water & drainage
  water_table     TEXT,
  irrigation_system SMALLINT,
  irrigation_type TEXT,
  drainage_class  SMALLINT,
  drainage_channels SMALLINT,
  underdrains     SMALLINT,
  brazda          CHAR(1),
  flood_risk      SMALLINT,

  -- Land cover & erosion
  land_cover      SMALLINT,
  land_cover_class TEXT,
  erosion_desc    TEXT,
  erosion_class   SMALLINT,
  erosion_risk    SMALLINT,
  erodibility     SMALLINT,

  -- Soil classification
  topsoil_h       SMALLINT,
  subsoil_j       SMALLINT,
  depth_class     SMALLINT,
  taw_class       SMALLINT,
  taw_100         NUMERIC(6,1),
  soil_type       TEXT,
  flooding_info   TEXT,

  -- Qualitative / DSS
  plant_health    SMALLINT,
  disease_pest    TEXT,
  phenology       TEXT,
  observations    TEXT,

  -- Data source tracking
  data_source     TEXT DEFAULT 'manual',  -- 'manual' | 'asig' | 'import'
  asig_parcel_id  TEXT,
  asig_land_use   TEXT,
  asig_suitability TEXT
);

-- ── SOIL HORIZONS ────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS soil_horizons (
  id              BIGSERIAL PRIMARY KEY,
  survey_id       BIGINT REFERENCES soil_surveys(id) ON DELETE CASCADE,
  horizon_order   SMALLINT NOT NULL,  -- 1..5

  horizon_label   TEXT,     -- e.g. Ap, B1, B2
  depth_from_cm   SMALLINT,
  depth_to_cm     SMALLINT,
  thickness_cm    SMALLINT,
  colour          TEXT,     -- Munsell code e.g. DR, GB
  mottles_o       TEXT,     -- abundance
  mottles_d       TEXT,     -- contrast
  mottles_rg      TEXT,     -- colour/shape
  texture_class   TEXT,     -- CL, SCL, L, etc.
  taw_group       TEXT,
  taw_mm_cm       NUMERIC(4,2),
  consistency     TEXT,
  ataw            NUMERIC(4,2),
  stones_pct      NUMERIC(5,1),
  stone_class     TEXT,
  stone_free_pct  NUMERIC(5,1),
  taw_mm_cols     NUMERIC(6,1)
);

-- ── METEO OBSERVATIONS ───────────────────────────────────────
CREATE TABLE IF NOT EXISTS meteo_observations (
  id              BIGSERIAL PRIMARY KEY,
  survey_id       BIGINT REFERENCES soil_surveys(id) ON DELETE CASCADE,
  created_at      TIMESTAMPTZ DEFAULT NOW(),

  -- Station & source
  meteo_station   TEXT,
  obs_date        DATE,
  obs_time        TIME,
  data_source     TEXT,  -- 'fuske_kruje' | 'copernicus' | 'manual' | 'era5'

  -- Temperature (°C)
  temp_min        NUMERIC(5,2),
  temp_max        NUMERIC(5,2),
  temp_mean       NUMERIC(5,2),
  lst             NUMERIC(5,2),  -- Land surface temp (Copernicus)
  soil_temp_10    NUMERIC(5,2),
  soil_temp_30    NUMERIC(5,2),

  -- Accumulated indicators
  gdd             NUMERIC(8,2),     -- Growing degree days
  chill_hours     NUMERIC(7,1),     -- Chilling hours < 7.2°C
  frost_days      SMALLINT,
  heat_stress_days SMALLINT,
  temp_anomaly    NUMERIC(5,2),

  -- Precipitation & humidity
  rainfall_daily  NUMERIC(7,2),
  rainfall_monthly NUMERIC(8,2),
  rainfall_seasonal NUMERIC(9,2),
  rainfall_anomaly NUMERIC(8,2),
  rh_min          NUMERIC(5,2),
  rh_max          NUMERIC(5,2),
  rh_mean         NUMERIC(5,2),
  dew_point       NUMERIC(5,2),

  -- Evapotranspiration & water balance
  eto             NUMERIC(6,3),
  etc             NUMERIC(6,3),
  water_deficit   NUMERIC(8,2),
  soil_water_balance NUMERIC(8,2),

  -- Soil moisture & remote sensing
  sm_10           NUMERIC(6,2),
  sm_30           NUMERIC(6,2),
  sm_60           NUMERIC(6,2),
  sm_index        NUMERIC(6,4),   -- Copernicus SWI

  -- Vegetation indices (Copernicus Sentinel-2)
  ndvi            NUMERIC(6,4),
  evi             NUMERIC(6,4),
  ndwi            NUMERIC(6,4),
  water_stress_class TEXT,

  -- Wind & radiation
  wind_speed      NUMERIC(6,2),
  wind_dir        TEXT,
  solar_rad       NUMERIC(7,3),
  sunshine_hrs    NUMERIC(5,2),

  -- Crop risk indicators
  disease_risk    TEXT,
  drought_stress  TEXT,
  alternate_bearing TEXT,
  meteo_notes     TEXT
);

-- ── INDEXES ──────────────────────────────────────────────────
CREATE INDEX IF NOT EXISTS idx_surveys_commune    ON soil_surveys(commune);
CREATE INDEX IF NOT EXISTS idx_surveys_qttb_area  ON soil_surveys(qttb_area);
CREATE INDEX IF NOT EXISTS idx_surveys_date       ON soil_surveys(survey_date);
CREATE INDEX IF NOT EXISTS idx_surveys_gps        ON soil_surveys(gps_n, gps_e);
CREATE INDEX IF NOT EXISTS idx_surveys_ref_no     ON soil_surveys(ref_no);
CREATE INDEX IF NOT EXISTS idx_horizons_survey    ON soil_horizons(survey_id);
CREATE INDEX IF NOT EXISTS idx_meteo_survey       ON meteo_observations(survey_id);
CREATE INDEX IF NOT EXISTS idx_meteo_date         ON meteo_observations(obs_date);

-- ── AUTO-UPDATE TIMESTAMP ─────────────────────────────────────
CREATE OR REPLACE FUNCTION update_updated_at()
RETURNS TRIGGER AS $$
BEGIN NEW.updated_at = NOW(); RETURN NEW; END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_surveys_updated_at
  BEFORE UPDATE ON soil_surveys
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- ── ROW LEVEL SECURITY (public read, authenticated write) ─────
ALTER TABLE soil_surveys        ENABLE ROW LEVEL SECURITY;
ALTER TABLE soil_horizons       ENABLE ROW LEVEL SECURITY;
ALTER TABLE meteo_observations  ENABLE ROW LEVEL SECURITY;

-- Allow anonymous reads (for demo/field use)
CREATE POLICY "Public read surveys"  ON soil_surveys        FOR SELECT USING (true);
CREATE POLICY "Public read horizons" ON soil_horizons       FOR SELECT USING (true);
CREATE POLICY "Public read meteo"    ON meteo_observations  FOR SELECT USING (true);

-- Allow anonymous inserts (field teams without login)
-- Change to authenticated only once you have user management set up:
-- USING (auth.role() = 'authenticated')
CREATE POLICY "Public insert surveys"  ON soil_surveys        FOR INSERT WITH CHECK (true);
CREATE POLICY "Public insert horizons" ON soil_horizons       FOR INSERT WITH CHECK (true);
CREATE POLICY "Public insert meteo"    ON meteo_observations  FOR INSERT WITH CHECK (true);

-- Allow update/delete only for the record creator (future: link to auth.uid())
CREATE POLICY "Public update surveys" ON soil_surveys FOR UPDATE USING (true);
CREATE POLICY "Public delete surveys" ON soil_surveys FOR DELETE USING (true);

-- ── USEFUL VIEWS ──────────────────────────────────────────────
CREATE OR REPLACE VIEW survey_summary AS
SELECT
  s.id, s.ref_no, s.commune, s.qttb_area, s.survey_date, s.surveyor,
  s.gps_n, s.gps_e, s.soil_type, s.taw_100, s.taw_class,
  s.land_cover_class, s.asig_suitability,
  s.erosion_risk, s.depth_class, s.plant_health,
  COUNT(h.id)  AS horizon_count,
  m.ndvi, m.sm_index, m.water_stress_class,
  m.temp_mean, m.rainfall_monthly, m.eto, m.gdd,
  s.created_at
FROM soil_surveys s
LEFT JOIN soil_horizons h      ON h.survey_id = s.id
LEFT JOIN meteo_observations m ON m.survey_id = s.id
GROUP BY s.id, m.id
ORDER BY s.created_at DESC;
