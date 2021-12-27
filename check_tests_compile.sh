
java8_home="/usr/lib/jvm/java-8-openjdk-amd64/jre"
java7_home="/usr/local/java/jdk1.7.0_80/"

if [ $# -eq 1 ] && [ $1 -eq 8 ];then
    mod=8
    compileLog="mvn-test-compile8.log"
    echo **** Running in Java8 mod ****
else
    mod=7
    compileLog="mvn-test-compile.log"
    echo **** Running in Java7 mod ****
fi

cp -r Repository/* ~/.m2/repository/
pwd=`pwd`

for proj in `ls Projects`; do
    for idx in `ls Projects/$proj`; do
        cd Projects/$proj/$idx 
        if [ mod -eq 8 ];then
            JAVA_HOME=$java8_home mvn clean test-compile -l $compileLog
        else
            JAVA_HOME=$java7_home mvn clean test-compile -l $compileLog
        fi
        if grep -q "\[INFO\] BUILD SUCCESS" $compileLog; then
            echo $proj-$idx build success
        elif grep -q "\[INFO\] BUILD FAILURE" $compileLog; then
            echo $proj-$idx build failed
        else 
            echo $proj-$idx ???
        fi
        
        cd $pwd
    done
done
        
