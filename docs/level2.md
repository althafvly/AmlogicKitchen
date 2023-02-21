# Working with the second level of Amlogic/Rockchip/AllWinner firmware

---

Instructions:

Note: run `bat` or `sh` depending on HOST OS

1. To work with the second level, you must unpack level 1 first

2. run unpack/rkunpack/awunpack and select 2

3. In the level2 folder, we replace/correct the files in the folders:

- system - system section
- vendor - vendor section
- product - product section
- system_ext - system_ext section
- odm - odm section
- oem - oem section
- system\_\* - system A/B section
- vendor\_\* - vendor A/B section
- product\_\* - product A/B section
- system*ext*\* - product A/B section
- odm\_\* - odm A/B section
- oem\_\* - oem A/B section

4. run pack/rkpack/awpack and select level 2

5. then to pack level 1 run pack and select level1 or to create full OTA, run pack_level1_fota

Notes:

- If you are adding new files or folders that require special permissions (by default, new files and folders are assigned permissions 0644 and 0755 when packing) then write these rights in \*\_fs_config.
- The \*\_file_contexts files are required for setting SELinux privileges
- And the \*\_size files set the size of a particular partition.
