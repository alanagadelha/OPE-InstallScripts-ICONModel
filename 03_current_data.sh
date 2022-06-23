#!/bin/bash
#  script current_data.sh
# ---------------------------------------------------------
if [ $# -ne 1 ]
then
     echo "Reference data (00 ou 12)!!!!!"
     exit
fi
HH=$1
# ---------------------------------------------------------
# Cleaning directory
rm -f /home/opicon/operacional/currentdates/currentdate$HH
rm -f /home/opicon/operacional/currentdates/icon_start_time$HH
rm -f /home/opicon/operacional/currentdates/icon_stop_time$HH
rm -f /home/opicon/operacional/currentdates/ANO${HH}
rm -f /home/opicon/operacional/currentdates/ano${HH}
rm -f /home/opicon/operacional/currentdates/mes${HH}
rm -f /home/opicon/operacional/currentdates/dia${HH}
rm -f /home/opicon/operacional/currentdates/diacorrente$HH
rm -f /home/opicon/operacional/currentdates/datacorrente_grads${HH}
#
#  Read and copy 
#
date +%Y%m%d > /home/opicon/operacional/currentdates/currentdate$HH
date +%Y-%m-%dT${HH}:00:00Z > /home/opicon/operacional/currentdates/icon_start_time${HH}
date --date='+5day' +%Y-%m-%dT${HH}:00:00Z > /home/opicon/operacional/currentdates/icon_stop_time${HH}
date +%Y >  /home/opicon/operacional/currentdates/ANO${HH}
date +%y >  /home/opicon/operacional/currentdates/ano${HH}
date +%m >  /home/opicon/operacional/currentdates/mes${HH}
date +%d >  /home/opicon/operacional/currentdates/dia${HH}
date +%d >  /home/opicon/operacional/currentdates/diacorrente$HH
date +%d%b%Y > /home/opicon/operacional/currentdates/datacorrente_grads${HH}
date --date='-1day' +%Y%m%d > /home/opicon/operacional/currentdates/datacorrente_m1${HH}
#
cat /home/opicon/operacional/currentdates/currentdate$HH
# END
