function out = supportHex_getHexCentersMagnified(hexCenters, mfactor, pix2deg)
    % center coordiantes kth row = kth polyshape, col1 = x, col2 = y\
    
    centersDeg = hexCenters.*pix2deg;
    [theta, rho] = cart2pol(centersDeg(:, 1), centersDeg(:, 2));
    s2 = rho.*(1 + rho/mfactor);
    [XM_deg, YM_deg] =  pol2cart(theta, s2);

    out = [XM_deg, YM_deg]./pix2deg;
end

