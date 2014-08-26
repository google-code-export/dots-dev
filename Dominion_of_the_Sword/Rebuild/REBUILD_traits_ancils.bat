REM Creating datasets...
g2dc.exe
REM Merging datasets...
tfm.exe
REM export_descr_ancillaries.txt & /text/export_ancillaries.txt
dots_replicator.exe templates\RAW_export_descr_ancillaries.txt "..\data\export_descr_ancillaries.txt" DATASET.yaml
dots_replicator.exe templates\text\RAW_export_ancillaries.txt "..\data\text\export_ancillaries.txt" DATASET.yaml -i utf-16le -o utf-16le
REM export_descr_character_traits.txt & /text/export_VnVs.txt
dots_replicator.exe -p? templates\RAW_export_descr_character_traits.txt templates\SUP_export_descr_character_traits.txt DATASET.yaml
dots_replicator.exe templates\SUP_export_descr_character_traits.txt "..\data\export_descr_character_traits.txt" DATASET.yaml
dots_replicator.exe templates\text\RAW_export_VnVs.txt "..\data\text\export_VnVs.txt" DATASET.yaml -i utf-16le -o utf-16le
del templates\SUP_export_descr_character_traits.txt