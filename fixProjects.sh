
pwd=`pwd`
for proj in `ls Projects`; do
    for idx in `ls Projects/"$proj"`; do
        if [ "$proj" = 'Closure' ]; then
            cd Projects/"$proj"/$idx
            sed -i 's_<version>r4314</version>_&\n      <scope>system</scope>\n      <systemPath>${project.basedir}/lib/caja-r4314.jar</systemPath>_g' pom.xml
            cd $pwd
        elif [ "$proj" = 'Lang' ]; then
            cd Projects/"$proj"/$idx
            sed -r -i 's_<maven.compile.(source|target)>1.6</maven.compile.\1>_<maven.compile.\1>1.8</maven.compile.\1>_g' pom.xml
            cd $pwd
        elif [ "$proj" = 'Math' ]; then
            cd Projects/"$proj"/$idx
            sed -i 's|<commons.jacoco.version>.*</commons.jacoco.version>|<commons.jacoco.version>0.8.4</commons.jacoco.version>|g' pom.xml
            cd $pwd
        elif [ "$proj" = 'Mockito' ]; then
            cd Projects/"$proj"/$idx
            cp -r mockmaker/bytebuddy/main/java/org/ src/
            cp -r mockmaker/bytebuddy/test/java/org/ test/
            cd $pwd
        else
            break
        fi
    done
done

