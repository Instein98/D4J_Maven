if [ $# -eq 1 ] && [ $1 -eq 8 ];then
    mvnTestList="mvnTestList8"
else
    mvnTestList="mvnTestList7"
fi

#cd TestLists
for d in TestLists/*/*; do
    echo ===== $d =====
    diff -s $d/d4jTestList $d/$mvnTestList
    echo
done
