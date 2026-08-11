const { Client } = require('pg');

const client = new Client({
  user: 'postgres',
  host: 'localhost',
  database: 'nubira_db',
  password: 'postgres',
  port: 5432,
});

async function seed() {
  await client.connect();
  console.log('Connected to DB');

  try {
    await client.query(`
      INSERT INTO articles (id, name, "defaultPieceRate", "createdAt") 
      VALUES 
        (gen_random_uuid(), 'ART-9921', 15.50, NOW()),
        (gen_random_uuid(), 'ART-4432', 12.00, NOW())
      ON CONFLICT (name) DO NOTHING;
    `);
    console.log('Seeded Articles');

    await client.query(`
      INSERT INTO lines (id, name, "isActive") 
      VALUES 
        (gen_random_uuid(), 'Line 1', true),
        (gen_random_uuid(), 'Line 2', true),
        (gen_random_uuid(), 'Line 3', true)
      ON CONFLICT (name) DO NOTHING;
    `);
    console.log('Seeded Lines');

    // Also seed a Lineman user
    // Password hash for 'password' using bcrypt
    const bcrypt = require('bcrypt');
    const hash = await bcrypt.hash('password', 10);
    await client.query(`
      INSERT INTO users (id, username, password, name, role) 
      VALUES (gen_random_uuid(), 'lineman1', $1, 'Raju (Line 1)', 'LINEMAN')
      ON CONFLICT (username) DO NOTHING;
    `, [hash]);
    console.log('Seeded Lineman');

  } catch (err) {
    console.error('Error seeding data:', err);
  } finally {
    await client.end();
  }
}

seed();
