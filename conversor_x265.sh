#!/bin/bash

#ffprobe -v error -select_streams v:0 -show_entries stream=codec_name -of default=noprint_wrappers=1:nokey=1 "$a"
#a=$(echo "$linha" | sed 's/\s/\\ /g')
#find -name "*.mp4" -type f -printf "%s " -print0 -printf "\n" | sort -h | sed 's/[0-9]*\s//'

find -name "00CONVERTENDO*" -type f | xargs -I {} rm "{}" #Exclui todos os arquivos que nao foram concluidos


if [ ! -f economiaEmBytes.DELETAR ]
then
    echo 0 > economiaEmBytes.DELETAR
fi

if [ ! -f lista.convertidos.DELETAR ]
then
    echo  > lista.convertidos.DELETAR
fi


echo \@@@@@ Economia total: $( numfmt --to=iec-i --suffix=B --format="%.3f" < economiaEmBytes.DELETAR ) #escreve bytes de forma legivel
rm lista.DELETAR lista.DELETAR.TAMANHO #evita adicionar arquivos duas vezes para a lista
find -name "*.mp4" -not -path "*/Symlinks/*"> lista.DELETAR 


while read linha
do
	stat -c "%s %n" "$linha" >> lista.DELETAR.TAMANHO
done < lista.DELETAR 

sort -h lista.DELETAR.TAMANHO | sed 's/[0-9]*\s//' > lista.DELETAR #Organiza a lista de arquivos em ordem de tamanho e retira a parte numerica

sort -h lista.DELETAR.TAMANHO > lista.DELETAR.TAMANHO.TEMPORARIO
rm lista.DELETAR.TAMANHO
mv lista.DELETAR.TAMANHO.TEMPORARIO lista.DELETAR.TAMANHO

tam_total=0
a=0	
num_de_arquivos=$( awk 'END{print NR}' < lista.DELETAR ) #numero de linhas no arquivo
tempo=0
tempo_inicio=0 #tempo que levou a ultima conversao

while read linha
do
	tam_total=$(( $( echo $linha | sed 's/\s\.\/.*//') + $tam_total ))

done < lista.DELETAR.TAMANHO

tam_media=$(( $tam_total / $num_de_arquivos ))

echo Tamanho total: $( echo $tam_total | numfmt --to=iec-i --suffix=B --format="%.3f" ) Tamanho medio: $( echo $tam_media | numfmt --to=iec-i --suffix=B --format="%.3f" )

#rm lista.DELETAR.TAMANHO #deleta arquivo com lista de tamanho

while read linha
do
	
	a=$((a+1))
	nome=$(basename "$linha")
	caminho=$(dirname "$linha")	
	tamanho=$(stat -c%s "$linha")
	economia=$(< economiaEmBytes.DELETAR)


	grep -w "$linha" lista.convertidos.DELETAR
	
	if [ "$?" = 0 ];
		then
			echo Arquivo "$a" ja foi convertido!
		else 
			tam_arquivo=$( sed "${a}q;d" < lista.DELETAR.TAMANHO )
			tam_arquivo=$( echo $tam_arquivo | sed 's/\s\.\/.*//' | numfmt --to=iec-i --suffix=B --format="%.3f" )

			echo Arquivo "$a" \(de "$num_de_arquivos" tam. $tam_arquivo\) \("$nome"\) ainda nao foi convertido! Ultimo levou \( $tempo min.\; econ. $economia_arquivo\; econ. tot. ses. $economia_sessao_echo\)
			codec=$(ffprobe -v error -select_streams v:0 -show_entries stream=codec_name -of default=noprint_wrappers=1:nokey=1 "$linha")


			if [ "$codec" = "h264" -a "$?" = 0 ];
				then
					tempo=$( date +%s )
					ffmpeg -y -loglevel panic -i "$linha" -c:a copy -c:v libx265 "$caminho/00CONVERTENDO$nome" </dev/null
					#avconv -y -loglevel panic -i "$linha" -c:a copy -c:v libx265 "$caminho/00CONVERTENDO$nome" </dev/null
					#echo $a $linha
					#sleep 5
					if [ "$?" = 0 ];
					then
						echo $linha >> lista.convertidos.DELETAR

						tamanhoFinal=$(stat -c%s "$caminho/00CONVERTENDO$nome")
						tamanho=$(( $tamanho - $tamanhoFinal ))
						economia=$(( $economia + $tamanho ))
						economia_arquivo=$economia
						economia_sessao=$(( $economia_sessao + $economia_arquivo ))
						economia_arquivo=$( echo $economia_arquivo | numfmt --to=iec-i --suffix=B --format="%.3f" )
						economia_sessao_echo=$( echo $economia_sessao | numfmt --to=iec-i --suffix=B --format="%.3f" )

						echo $economia > economiaEmBytes.DELETAR
						mv "$caminho/00CONVERTENDO$nome" "$caminho/$nome"

						tempo=$(( ($(date +%s) - tempo)/60 ))
					fi
				else
					echo \!\!\!\!\! Arquivo ja esta no formato correto
			fi

	fi  

	 
	#a=$((a+1))    
	#echo "$a $codec"
	
done < lista.DELETAR
echo \##### Economia total: $( numfmt --to=iec-i --suffix=B --format="%.3f" < economiaEmBytes.DELETAR )
