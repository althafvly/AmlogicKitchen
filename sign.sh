# Resign to AOSP keys
echo "Resigning to AOSP keys"
dir=$(echo "$(pwd)")
security=$(echo "$(pwd)/ROM_resigner/AOSP_security")

for part in system_a system_ext_a vendor_a product_a odm_a system system_ext vendor product odm; do
    if [ -d $dir/level2/$part ]; then
        if [ $part == system_a ] || [ $part == system ] && [ -d $dir/level2/$part/system ]; then
            if [ -d $dir/level2/$part/system/etc/selinux ] && [ -f $dir/level2/$part/system/etc/selinux/*_mac_permissions.xml ]; then
                python $dir/ROM_resigner/resign.py $dir/level2/$part/system $security selinux
            fi
        else
            if [ -d $dir/level2/$part/etc/selinux ] && [ -f $dir/level2/$part/etc/selinux/*_mac_permissions.xml ]; then
                python $dir/ROM_resigner/resign.py $dir/level2/$part $security selinux
            fi
            if [ -d $dir/level2/$part/etc/security ] && [ -f $dir/level2/$part/etc/security/mac_permissions.xml ]; then
                python $dir/ROM_resigner/resign.py $dir/level2/$part $security security
            fi
        fi
    fi
done
