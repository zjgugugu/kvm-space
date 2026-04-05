#!/bin/bash
# Fix deployed DB schema - add missing columns
NODE=/usr/local/bin/node14
cd /opt/kvm-space/server

$NODE -e '
var path = require("path");
var wrapper = require("./src/db/sqlite-wrapper");
wrapper.openDatabase("./data/kvm-cloud.db").then(function(db) {
  // Check existing tables
  var tables = db.exec("SELECT name FROM sqlite_master WHERE type='\''table'\'' ORDER BY name");
  console.log("Tables:", tables.length ? tables[0].values.map(function(v){return v[0]}).join(", ") : "none");
  
  // Fix recycle_bin - add created_at if table exists but column missing
  try {
    db.exec("SELECT created_at FROM recycle_bin LIMIT 1");
    console.log("recycle_bin.created_at: OK");
  } catch(e) {
    console.log("recycle_bin: fixing...", e.message);
    try {
      db.exec("ALTER TABLE recycle_bin ADD COLUMN created_at DATETIME DEFAULT (datetime('\''now'\''))");
      console.log("recycle_bin.created_at: ADDED");
    } catch(e2) {
      // Table might not exist, create it
      db.exec("CREATE TABLE IF NOT EXISTS recycle_bin (id TEXT PRIMARY KEY, resource_type TEXT NOT NULL, resource_id TEXT NOT NULL, resource_name TEXT DEFAULT '\'''\'', deleted_by TEXT DEFAULT '\'''\'', original_data TEXT DEFAULT '\'''\'', expires_at DATETIME, created_at DATETIME DEFAULT (datetime('\''now'\'')))");
      console.log("recycle_bin: CREATED");
    }
  }
  
  // Check desktop_pools
  try {
    db.exec("SELECT * FROM desktop_pools LIMIT 1");
    console.log("desktop_pools: OK");
  } catch(e) {
    console.log("desktop_pools: missing, will be created on restart");
  }

  console.log("Done");
});
'
