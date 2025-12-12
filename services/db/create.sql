SELECT 'CREATE DATABASE area_db' WHERE NOT EXISTS (SELECT FROM pg_database WHERE datname = 'area_db')\gexec
CREATE TABLE services (
    id SERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    color VARCHAR(255) NOT NULL,
    icon VARCHAR(255) NOT NULL,
    subscribable BOOLEAN NOT NULL DEFAULT FALSE
);
INSERT INTO services (name, color, icon, subscribable) VALUES
('Mail', '#e5b900', 'email', False),
('Heure et date', '	#99abb3', 'date_range', False),
('Météo', '#69a2cc', 'weather', False),
('Discord', '#7289da', 'discord', True),
('Spotify', '#1db954', 'spotify', True),
('Github', '#424242', 'github', True),
('Dropbox', '#007ee5', 'dropbox', True),
('Espace', '#5643fd', 'space', False),
('Cryptomonnaie', '#f7931a', 'bitcoin', False),
('Forex', '#590059', 'euro_symbol', False),
('Google Docs', '#004b89', 'google_docs', True);