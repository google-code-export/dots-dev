REM Creating datasets...
g2dc.exe
REM Merging datasets...
tfm.exe
REM export_descr_buildings.txt (EDB) & /text/export_buildings.txt & descr_building_battle.txt & /text/building_battle.txt
dots_replicator.exe -p? templates\RAW_export_descr_buildings.txt templates\SUP_export_descr_buildings.txt DATASET.yaml
dots_replicator.exe templates\SUP_export_descr_buildings.txt templates\SUP1_export_descr_buildings.txt DATASET.yaml
dots_replicator.exe -p@ templates\SUP1_export_descr_buildings.txt "..\data\export_descr_buildings.txt" DATASET.yaml
dots_replicator.exe -p? templates\text\RAW_export_buildings.txt templates\text\SUP_export_buildings.txt DATASET.yaml -i utf-16le -o utf-16le
dots_replicator.exe templates\text\SUP_export_buildings.txt "..\data\text\export_buildings.txt" DATASET.yaml -i utf-16le -o utf-16le
dots_replicator.exe templates\RAW_descr_building_battle.txt "..\data\descr_building_battle.txt" DATASET.yaml
dots_replicator.exe templates\text\RAW_building_battle.txt "..\data\text\building_battle.txt" DATASET.yaml -i utf-16le -o utf-16le
del templates\SUP_export_descr_buildings.txt
del templates\SUP1_export_descr_buildings.txt
del templates\text\SUP_export_buildings.txt