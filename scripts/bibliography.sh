#!/bin/bash

# Erzeugt für Dokumente individuelle Literaturverzeichnisse
#
# Funktionsweise:
# - common/bibliography.adoc enthält alle Literaturrefenzen in der Form [[[BibRef]]]. Baue eine Liste aller Referenzen (1)
# - Suche in adoc-Dateien aller Dokumente (2) nach Referenzen der Form <<BibRef>> (3)
# - Extrahiere für jede gefundene Referenz den Eintrag aus bibliography.adoc und übernehme in indiviuelle
#   bibliography.adoc des Dokuments (4)

# (1)
#allBibRefs=($(gawk 'match($0, /\[\[\[(.+)\]\]\]/, m) { print m[1]}' $curDir/common/bibliography.adoc))
allBibRefs() {
    gawk 'match($0, /\[\[\[(.+)\]\]\]/, m) { print m[1]}' $curDir/common/bibliography.adoc | sort -u
}

# (3)
findRefs() {

    if [ -f $dir/grabbedRefs.txt ];
    then
      rm $dir/grabbedRefs.txt
    fi
    touch $dir/grabbedRefs.txt
    cat $dir/docinfo.adoc $dir/thisdoc.adoc $dir/inhalt.adoc $dir/anhaenge.adoc > $dir/RefSrc-temp.adoc

    for Ref2 in $@
    do
        cat $dir/RefSrc-temp.adoc | gawk '{while(match($0,/<<([^<>]+)>>/)) {print substr($0,RSTART+2,RLENGTH-4); $0=substr($0,RSTART+RLENGTH)}}' | grep $Ref2 | sort -u >> $dir/grabbedRefs.txt
    done

    touch $dir/grabbedRefs-temp.txt
    cat $dir/grabbedRefs.txt | sort -u > $dir/grabbedRefs-temp.txt
    cat $dir/grabbedRefs-temp.txt > $dir/grabbedRefs.txt

    cat $dir/grabbedRefs.txt

    if [ -f $dir/grabbedRefs-temp.txt ];
    then
      rm $dir/grabbedRefs-temp.txt
    fi

    if [ -f $dir/grabbedRefs.txt ];
    then
      rm $dir/grabbedRefs.txt
    fi
    rm $dir/RefSrc-temp.adoc
}

# (4)
buildDocumentBibliography() {
    refs=($@)
    refsSize=${#refs[@]}

    if [ $refsSize -gt 0 ]
    then
        echo -e "[bibliography]\n== Literaturverweise" > $dir/bibliography.adoc

        for ref in $@
        do
          gawk -v foundref=$ref 'match($1, /\[\[\[(.+)\]\]\]/, m) && m[1] == foundref { print $0 }' RS='' FS='\n' $curDir/common/bibliography.adoc | tee -a $dir/bibliography.adoc
        done
    else
        touch $dir/bibliography.adoc
    fi
}

allDocDirCmd() {
    find $ArgOneDir/10_* $ArgOneDir/20_* -name master.adoc | xargs dirname
}

# (1)

echo "Generating document dependent bibliographies...."

curDir=$(pwd)
#echo "DEBUG: started in " $curDir

# wechsele in das übergebene Verzeichnis
cd $1
ArgOneDir=$(pwd)

#echo "DEBUG: got ArgOne " $ArgOneDir

allDocDirectories=($(eval "allDocDirCmd"))

# wechsele in das übergebene Arbeitsverzeichnis
cd $curDir

# (2)

allBibEntries=($(eval "allBibRefs"))

for igt in ${allBibEntries[@]}; do
  echo " BibEntries : " $igt
done

for dir in ${allDocDirectories[@]}
do
    echo " Ziel: " $dir
    bibRefs=($(findRefs "${allBibEntries[@]}"))
    #for igt22 in ${bibRefs[@]}; do
    #  echo " BibRef : " $igt22
    #done
    buildDocumentBibliography "${bibRefs[@]}"
done
