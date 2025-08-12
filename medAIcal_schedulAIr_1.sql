-- Patients
CREATE TABLE patients (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  insurance_provider TEXT NOT NULL
);

-- Past visit notes (1:N with patients)
CREATE TABLE patient_notes (
  id SERIAL PRIMARY KEY,
  patient_id TEXT NOT NULL REFERENCES patients(id) ON DELETE CASCADE,
  note TEXT NOT NULL
);

-- Keyword “t-SNE-like” map (1:N with patients)
CREATE TABLE patient_keywords (
  id SERIAL PRIMARY KEY,
  patient_id TEXT NOT NULL REFERENCES patients(id) ON DELETE CASCADE,
  label TEXT NOT NULL,
  x DOUBLE PRECISION NOT NULL,
  y DOUBLE PRECISION NOT NULL
);


-- Patients
INSERT INTO patients (id, name, insurance_provider) VALUES
('p1','Alice Johnson','Blue Cross Blue Shield'),
('p2','Brian Patel','Aetna'),
('p3','Chloe Kim','UnitedHealthcare'),
('p4','Diego Sanchez','Cigna'),
('p5','Elaine Wong','Humana');

-- Notes
INSERT INTO patient_notes (patient_id, note) VALUES
('p1','2025-07-10: Follow-up on hypertension. Adjusted medication.'),
('p1','2025-06-02: Routine checkup. Recommended increased exercise.'),
('p1','2025-05-14: Mild dizziness reported. Ordered labs.'),
('p2','2025-07-29: Asthma check. Inhaler technique reviewed.'),
('p2','2025-05-21: Seasonal allergies. Antihistamine prescribed.'),
('p3','2025-07-18: Prediabetes counseling. Diet & exercise plan.'),
('p3','2025-04-09: Lipid panel elevated. Statin discussed.'),
('p4','2025-06-30: Knee pain. Physical therapy referral.'),
('p4','2025-03-19: Imaging (MRI) reviewed. No tear.'),
('p5','2025-07-05: Migraine management. Triptan effective.'),
('p5','2025-02-11: Sleep hygiene discussed.');

-- Keyword map
INSERT INTO patient_keywords (patient_id, label, x, y) VALUES
('p1','hypertension', -0.8,  0.6),
('p1','dizziness',    -0.2,  0.1),
('p1','labs',          0.1, -0.4),
('p1','exercise',      0.7,  0.2),
('p1','medication',   -0.5, -0.7),

('p2','asthma',       -0.7, -0.2),
('p2','inhaler',      -0.3,  0.8),
('p2','allergies',     0.2,  0.5),
('p2','antihistamine', 0.8, -0.3),

('p3','prediabetes',  -0.6,  0.4),
('p3','diet',         -0.1, -0.8),
('p3','exercise',      0.4, -0.6),
('p3','lipids',        0.6,  0.7),
('p3','statin',        0.9, -0.1),

('p4','knee pain',    -0.9, -0.1),
('p4','PT',           -0.4,  0.3),
('p4','MRI',           0.3,  0.9),
('p4','referral',      0.5, -0.4),

('p5','migraine',     -0.2,  0.9),
('p5','triptan',       0.1,  0.2),
('p5','sleep',         0.7, -0.5),
('p5','hygiene',      -0.6, -0.6);
