cp -r Repository/* ~/.m2/repository/
pwd=`pwd`

for proj in `ls Projects`; do
    for idx in `ls Projects/$proj`; do
        cd Projects/$proj/$idx 
        #[[ ! -f mvn-test-compile.log || ! -s mvn-test-compile.log ]] && mvn clean test-compile -l mvn-test-compile.log
        mvn clean test-compile -l mvn-test-compile.log
        if grep -q "\[INFO\] BUILD SUCCESS" mvn-test-compile.log; then
            echo $proj-$idx build success
        elif grep -q "\[INFO\] BUILD FAILURE" mvn-test-compile.log; then
            echo $proj-$idx build failed
        else 
            echo $proj-$idx ???
        fi
        
        cd $pwd
    done
done
        
