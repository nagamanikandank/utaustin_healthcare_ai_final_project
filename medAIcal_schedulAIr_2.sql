CREATE OR REPLACE VIEW patient_full AS
SELECT
  p.id,
  p.name,
  p.insurance_provider,
  COALESCE(array_agg(DISTINCT pn.note) FILTER (WHERE pn.id IS NOT NULL), '{}') AS past_notes,
  COALESCE(
    json_agg(DISTINCT jsonb_build_object('label', pk.label, 'x', pk.x, 'y', pk.y))
    FILTER (WHERE pk.id IS NOT NULL),
    '[]'
  ) AS keyword_map
FROM patients p
LEFT JOIN patient_notes pn ON pn.patient_id = p.id
LEFT JOIN patient_keywords pk ON pk.patient_id = p.id
GROUP BY p.id, p.name, p.insurance_provider
ORDER BY p.id;
