REM Creating datasets...
g2dc.exe
REM Merging datasets...
tfm.exe
REM descr_names.txt & /text/names.txt
dots_replicator.exe -p? templates\RAW_descr_names.txt templates\SUP_descr_names.txt DATASET.yaml
dots_replicator.exe templates\SUP_descr_names.txt "..\data\descr_names.txt" DATASET.yaml
dots_replicator.exe -p? templates\text\RAW_names.txt templates\text\SUP_names.txt DATASET.yaml -i utf-16le -o utf-16le
dots_replicator.exe templates\text\SUP_names.txt "..\data\text\names.txt" DATASET.yaml -i utf-16le -o utf-16le
del templates\text\SUP_names.txt
del templates\SUP_descr_names.txt