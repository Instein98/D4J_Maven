pluginForMockito="  <plugin>\n    <groupId>org.codehaus.mojo</groupId>\n    <artifactId>build-helper-maven-plugin</artifactId>\n    <version>3.2.0</version>\n    <executions>\n        <execution>\n        <id>add-source</id>\n        <phase>generate-sources</phase>\n        <goals>\n          <goal>add-source</goal>\n        </goals>\n        <configuration>\n          <sources>\n            <source>mockmaker/bytebuddy/main/java</source>\n          </sources>\n        </configuration>\n      </execution>\n      <execution>\n        <id>add-test-source</id>\n        <phase>generate-test-sources</phase>\n        <goals>\n          <goal>add-test-source</goal>\n        </goals>\n        <configuration>\n          <sources>\n            <source>mockmaker/bytebuddy/test/java</source>\n          </sources>\n        </configuration>\n      </execution>\n    </executions>\n  </plugin>"

# add caja to Repository
mkdir -p Repository/caja/caja/r4314/
cp Projects/Closure/1/lib/caja-r4314.jar Repository/caja/caja/r4314/

# fix pom.xml for Mockito
pwd=`pwd`
for proj in `ls Projects`; do
    for idx in `ls Projects/"$proj"`; do
        if [ "$proj" = 'Mockito' ]; then
            if [[ $idx -ne 1 && $idx -ne 3 && $idx -ne 18 && $idx -ne 19 && $idx -ne 38 ]]; then
                continue
            fi
            echo Fixing $proj-$idx
            cd Projects/"$proj"/$idx
            sed -i "s,<plugins>,&\n$pluginForMockito," pom.xml
            if [ $idx -eq 38 ]; then
                sed -i 's_<version>1.0-own</version>_&\n      <scope>system</scope>\n      <systemPath>${project.basedir}/lib/build/jarjar-1.0.jar</systemPath>_g' pom.xml
            fi
            cd $pwd
        else
            break
        fi
    done
done

