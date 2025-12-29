-- PostgreSQL version of states.sql

BEGIN;

-- Drop table if it exists (optional)
DROP TABLE IF EXISTS states;

-- Create table
CREATE TABLE states (
    id BIGSERIAL PRIMARY KEY,
    name VARCHAR(150) NOT NULL
);

-- Insert data
INSERT INTO states (id, name) VALUES
    (1, 'Tunis'),
    (2, 'Ariana'),
    (3, 'Manouba'),
    (4, 'Ben Arous'),
    (5, 'Nabeul'),
    (6, 'Bizerte'),
    (7, 'Zaghouan'),
    (8, 'Sousse'),
    (9, 'Monastir'),
    (10, 'Mahdia'),
    (11, 'Sfax'),
    (12, 'Beja'),
    (13, 'Jendouba'),
    (14, 'Le Kef'),
    (15, 'Siliana'),
    (16, 'Kairouan'),
    (17, 'Sidi Bouzid'),
    (18, 'Kasserine'),
    (19, 'Gabes'),
    (20, 'Medenine'),
    (21, 'Gafsa'),
    (22, 'Tozeur'),
    (23, 'Tataouine'),
    (24, 'Kebili');

COMMIT;
