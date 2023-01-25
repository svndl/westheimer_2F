    function out = supportHex_mkWhole(quarter)
        % rotate 
        quarter = quarter';
        hexMap_tophalf= [quarter(end:-1:1, end:-1:1) quarter(end:-1:1, :)];
        out = [hexMap_tophalf; hexMap_tophalf(end:-1:1, :)];                
    end
