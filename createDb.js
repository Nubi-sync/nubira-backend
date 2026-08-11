const { Client } = require('pg');

const client = new Client({
  host: 'localhost',
  port: 5432,
  user: 'postgres',
  password: 'postgres',
  database: 'postgres' 
});

async function createDb() {
  try {
    await client.connect();
    console.log("Connected to default postgres database.");
    await client.query('CREATE DATABASE nubira_db;');
    console.log("Database nubira_db created successfully.");
  } catch (err) {
    if (err.code === '42P04') {
        console.log("Database nubira_db already exists.");
    } else {
        console.error("Error creating database:", err);
    }
  } finally {
    await client.end();
  }
}

createDb();
