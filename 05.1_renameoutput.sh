#!/bin/bash -xl
#
#  Script para modificar os nomes dos arquivos de previsao
#  de todas as areas do modelo iconlam.
#
#
# Autor: CT(T) Neris

#*****************************************************************************
#  passo 1 - verifica args passados
#

if [ $# -lt 4 ];then
	echo "Entre com a area, o horario da rodada (00 ou 12), o prognostico inicial e final!!!"
	exit 12
fi

AREA=$1
HH=$2
HSTART=$3
HSTOP=$4

case $AREA in

met)
WORKDIR='/home/admcosmo/cosmo/metarea5'
AREA=met
INT=3
;;
ant)
WORKDIR='/home/admcosmo/cosmo/antartica'
AREA2=ant
INT=3
;;
#sse)
#WORKDIR='/home/admcosmo/cosmo/sse'
#AREA2=sse
#INT=1
#;;
*)
echo " Area nao cadastrada "
exit 12
;;
esac


#*****************************************************************************
#  passo 2 - Define variaveis.
#iconlam_met_12_20220607T120000.000Z_ml_0001.grb


HH=$1

DATE=`cat ~/operacional/data/currentdates/currentdate${HH}`
outdir="/home/opicon/operacional/data/outputdata${HH}"

for num in `seq 1 1 41`; do

	cp `ls -l ${outdir}/iconlam_*ml.grb | cut -d" " -f10 | head -${num} | tail -1` ${outdir}/iconlam_met_${HH}_${DATE}_`printf "%03g" $((num*3-3))`_ml.grb

done
