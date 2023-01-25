function maskOut = supportHex_makeMask_CM(center, R, n_sides, msize, mfactor, pix2deg)
    maskOut = zeros(msize);
    % center coordiantes kth row = kth polyshape, col1 = x, col2 = y
    for c = 1:size(center, 1)
        [xr, yr] = someShapeMagnified(center(c, :), R, n_sides + 1, mfactor, pix2deg);
        maskOut = maskOut + poly2mask(floor(xr), floor(yr), msize(1), msize(2));
    end
end

function [XM, YM] = someShapeMagnified(center, radius, n, k, pix2deg)
    
    t = linspace(0, 2*pi, n);
    r = radius*ones(1, n);

    X = r.*sin(t) + center(1);
    Y = r.*cos(t) + center(2);

    xD = X*pix2deg;
    yD = Y*pix2deg;

    [theta, rho] = cart2pol(xD, yD);

    s2 = rho.*(1 + rho/k);
    %s2 = rho.*(1 + rho/(k*k));
    
    
    [XM_deg, YM_deg] =  pol2cart(theta, s2);

    XM = XM_deg/pix2deg;
    YM = YM_deg/pix2deg;
end

