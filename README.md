# QTTB DSS — Decision Support System
### Joint venture Studio Bagnara & Cà Colonna srl

Field survey data collection and agronomic decision support system for QTTB production areas in Albania. Integrates live data from ASIG geoportal and Copernicus Earth Observation.

---

## Production areas
| Zone | Crop | ASIG data |
|------|------|-----------|
| Fushë Krujë | ATTC headquarters | `perdorimi_tokes_2020`, `pedologjia_23042024`, `Tipet_e_tokes_07082019`, `Pershtatshmeria_07082019` |
| Korçë | Apple | Chilling hours, frost risk |
| Lushnje | Tomato | Irrigation scheduling, heat stress |
| Vlorë | Olive | Drought monitoring, alternate bearing |

---

## Quick start

### Option A — Open directly (form only, no live queries)
```
open index.html
```

### Option B — Full live data (ASIG + Copernicus queries)
```bash
python -m http.server 8080
# then open http://localhost:8080
```

### Option C — Deploy to GitHub Pages
```bash
git push origin main
# Enable GitHub Pages in repo Settings → Pages → Branch: main
# Access at: https://yourusername.github.io/qttb-dss/
```

---

## Database setup (Supabase — free)

1. Create a free account at [app.supabase.com](https://app.supabase.com)
2. Create a new project (choose Frankfurt region for lowest latency from Albania)
3. Go to **SQL Editor** and run `db/schema.sql`
4. Go to **Settings → API** and copy:
   - **Project URL** → `https://xxxxxxxxxxxx.supabase.co`
   - **anon public key** → `eyJ...`
5. Open `index.html` and click the **⚙ Database** button in the header
6. Paste your URL and key — the form will save all records to Supabase

---

## Copernicus Data Space setup (free)

1. Register at [dataspace.copernicus.eu](https://dataspace.copernicus.eu)
2. Go to Dashboard → User Settings → OAuth clients → Create new client
3. In the form, go to **Meteo variables** tab → paste Client ID and Client Secret
4. Click **Test connection** → **Fetch indices for current GPS**

Free tier: 30,000 processing units/month — sufficient for daily field surveys.

---

## Data APIs connected

| API | Endpoint | Auth | Data |
|-----|----------|------|------|
| ASIG QTTB | `geoportal.asig.gov.al/service/qttb/ows` | None (public) | Land use, pedology, suitability, olive/vineyard cadastre |
| ASIG ZRPP | `geoportal.asig.gov.al/service/zrpp/ows` | None (public) | Cadastral parcels (Apr 2025) |
| Copernicus S-2 | `sh.dataspace.copernicus.eu/api/v1/process` | OAuth2 | NDVI, EVI, NDWI |
| Copernicus S-1 | `sh.dataspace.copernicus.eu/api/v1/process` | OAuth2 | Soil moisture backscatter |
| Copernicus GLS | `land.copernicus.eu/api/v1/products/SSM` | None | Soil moisture index (no key needed) |

---

## ASIG layer names (confirmed from live GetCapabilities)

```
geoportal.asig.gov.al/service/qttb/ows

perdorimi_tokes_2020          Land use 2020 (parcel level)
perdorimi_tokes_zone_2020     Land use overview
pedologjia_23042024           Pedology (national, Apr 2024)
Tipet_e_tokes_07082019        Soil types 2019
Tipet_e_tokes_zone            Soil types overview
Pershtatshmeria_07082019      Land suitability 2019
Pershtatshmeria_zone          Suitability overview
kadastra_e_ullishteve         Olive Cadastre (national)
kadastra_e_vreshtave          Vineyard Cadastre (national)
```

---

## Project structure

```
qttb-dss/
├── index.html          Main DSS form (soil survey + meteo + GIS map)
├── db/
│   └── schema.sql      Supabase PostgreSQL schema
├── docs/
│   └── references/     LUPP2 technical reports (ATTC proforma templates)
├── exports/            Downloaded GeoJSON / CSV exports
└── README.md
```

---

## Survey form — data sources per field

| Field | Source |
|-------|--------|
| GPS E/N | Manual entry or map click |
| Commune | Location selector or typed |
| Land cover class | ASIG `perdorimi_tokes_2020` |
| Soil type | ASIG `pedologjia_23042024` |
| Suitability class | ASIG `Pershtatshmeria_07082019` |
| Parcel ID | ASIG ZRPP `parcela_kadastrale_qkd_042025` |
| NDVI / EVI / NDWI | Copernicus Sentinel-2 L2A |
| Soil moisture index | Copernicus Sentinel-1 GRD |
| Temperature / rainfall | Manual / Fushë Krujë station |
| GDD / chilling hours | Computed from temperature |

---

## Reference data included
- **Ref. 133** — Real survey, Prezë commune, Fushë Krujë, 15.03.2003, surveyor Gr. Sulçkrani
  - 4 horizons: 0–30cm CL, 30–50cm CL, 50–90cm SCL, 90–160cm L
  - TAW = 166mm, depth class 1 (>120cm), drainage imperfect
  - Source: Soil Research Institute Tirana / LUPP2 / Land Use Policy Project AL 98-05-02

---

## References
- LUPP2 Technical Report 4: *Procedures for a Soil and Land Survey of Agricultural Land* — Agrotec SpA Consortium / Soil Research Institute Tirana (2003)
- ASIG Geoportal: [geoportal.asig.gov.al](https://geoportal.asig.gov.al)
- Copernicus Data Space: [dataspace.copernicus.eu](https://dataspace.copernicus.eu)
