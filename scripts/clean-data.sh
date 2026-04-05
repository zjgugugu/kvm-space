#!/bin/bash
# Clean all stale test data from DB, keeping only real hardware info
NODE=/usr/local/bin/node14
cd /opt/kvm-space/server

$NODE -e '
var path = require("path");
var wrapper = require("./src/db/sqlite-wrapper");
wrapper.openDatabase("./data/kvm-cloud.db").then(function(db) {
  // Clean all test data tables
  var tables = [
    "vms", "vm_disks", "vm_nics", "snapshots",
    "templates", "template_versions",
    "desktop_specs", "publish_rules", "desktop_pools",
    "networks", "security_groups", "security_rules", "vm_security_groups",
    "mac_pools", "subnets",
    "storage_pools", "volumes",
    "events", "alerts", "alert_settings",
    "tasks", "approvals", "audit_logs",
    "backups", "backup_servers",
    "snapshot_policies", "snapshot_policy_vms",
    "recycle_bin",
    "app_layers", "software_library", "software_publish",
    "app_control_rules", "virtual_app_groups", "virtual_app_sessions",
    "scaling_strategies", "scaling_groups",
    "managed_files", "terminals", "terminal_bindings",
    "detection_results", "zombie_servers",
    "port_mirroring", "vlan_pools", "port_groups"
  ];
  
  tables.forEach(function(t) {
    try {
      db.exec("DELETE FROM [" + t + "]");
      console.log("Cleaned: " + t);
    } catch(e) {
      console.log("Skip: " + t + " (" + e.message.substring(0, 40) + ")");
    }
  });
  
  // Keep hosts but update with real hardware data
  db.exec("DELETE FROM hosts");
  db.prepare("INSERT INTO hosts (id, name, ip, role, cpu_model, cpu_total, cpu_used, mem_total, mem_used, disk_total, disk_used, net_speed, status, arch, os, kernel) VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)").run(
    "00f157d5-2e22-416e-b38f-6a7449648adc",
    "node1",
    "10.126.33.238",
    "CM_VDI",
    "HUAWEI Kunpeng 920 7262C",
    64, 0,
    261515, 0,
    3600, 0,
    10000,
    "online",
    "aarch64",
    "Kylin Linux Advanced Server V10",
    "4.19.90-24.4.v2101.ky10.aarch64"
  );
  console.log("Host node1 created with real hardware data");
  
  // Keep users (admin accounts)
  // Users are kept from initDefaultData
  
  // Keep sys_config
  // sys_config is kept from initDefaultData 
  
  // Clean user_groups
  try { db.exec("DELETE FROM user_groups"); console.log("Cleaned: user_groups"); } catch(e) {}
  
  // Clean clusters
  try { db.exec("DELETE FROM clusters"); console.log("Cleaned: clusters"); } catch(e) {}
  
  console.log("=== Data cleanup complete ===");
});
'
