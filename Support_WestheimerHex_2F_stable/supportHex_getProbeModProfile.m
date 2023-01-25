 function out = supportHex_getProbeModProfile(nPoints, modProfile, contrastDirection)
 
    %sawtooth_fcn = @(x, a, w) a/w*(x - (w*fix(x/w)));
    %x0 = linspace(0, nPoints - 1, nPoints);
    switch contrastDirection
        case 'Above'
            % by default off
            contrast_profile = linspace(0, 1, nPoints);
            %contrast_profile = sawtooth_fcn(x0, nPoints, nPoints)/(nPoints - 1);
        case 'Below'
            contrast_profile = linspace(-1, 0, nPoints);            
        case 'Symmetric'
            %contrast_profile = (sawtooth_fcn(x0, 2*nPoints, nPoints/2) - nPoints)/(nPoints);
            % half stimulus
            
            contrast_profile = linspace(0, 1, nPoints) - 0.5;
    end
    
    switch modProfile
        case 'Sawtooth-on'
            out = contrast_profile(end:-1:1);
        case 'Sawtooth-off'
            out = contrast_profile;
    end
 end