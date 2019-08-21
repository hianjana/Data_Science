now="$(date +'%d_%m_%Y')"
path1="/home/ubuntu/crawled_files/lefashion/"
path2="/home/ubuntu/crawled_files/thebluehydrangeas/"
path3="/home/ubuntu/crawled_files/dressedinIbiza/"
path4="/home/ubuntu/crawled_files/fashiontrends/"
path5="/home/ubuntu/crawled_files/songofstyle/"
path6="/home/ubuntu/crawled_files/elle/"
path7="/home/ubuntu/crawled_files/whowhatwear/"
outputdir1=$path1$now
outputdir2=$path2$now
outputdir3=$path3$now
outputdir4=$path4$now
outputdir5=$path5$now
outputdir6=$path6$now
outputdir7=$path7$now
mkdir -p "$outputdir1"
mkdir -p "$outputdir2"
mkdir -p "$outputdir3"
mkdir -p "$outputdir4"
mkdir -p "$outputdir5"
mkdir -p "$outputdir6"
mkdir -p "$outputdir7"
echo 'Directories successfully created!!!'