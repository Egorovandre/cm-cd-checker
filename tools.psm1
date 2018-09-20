# *
#  * @Author: vitali.skuratovich 
#  * @Date: 2018-06-13 11:35:03 
#  * @Last Modified by:   vitali.skuratovich 
#  * @Last Modified time: 2018-06-13 11:35:03 
#  *


$logfile = ".\logs\$(Get-Date -Format yyyyMMdd_HHmm).log"

#Function for creating logs.
# Two log details USER and FULL

Function LogWrite {
    #
    Param (
       [string]$logstring
           )
           Add-content $logfile -value $logstring
    
}
function configEnable {
    
}

function configDisable {
    
}