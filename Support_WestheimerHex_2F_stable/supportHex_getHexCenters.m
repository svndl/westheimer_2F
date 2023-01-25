function hexCenters = supportHex_getHexCenters(stimset_base, video_minDim, video_pix2arcmin)
%% function will generate hexagon centers basing on stimset, video parameters

   
   %max number of hexagons after magnification effect 
   nMaxHex = 1 + getMaxHex(video_minDim, stimset_base.mFactor, stimset_base.size_pix, video_pix2arcmin/60);
   %start at top left corner and map lower quarter (IV Quadrant))
   x0 = 0;
   y0 = 0;
   % hex centers
   hexCenters0 = computeHexCenters(x0, y0, stimset_base.size_pix, nMaxHex);
   h0 = removeMeridianCenters(hexCenters0, 'fov');
   hexCenters = cell2mat(h0);
end

function nHex = getMaxHex(height, k, r, pix2deg)
    % max visual field degree, half
    max_Xdeg = (0.5*height)*pix2deg;
    
    % what point will project to max visual field degree, half
    max_Xdeg_new = 0.5*(-k + sqrt(k^2 + 4*k*max_Xdeg))/pix2deg;
    nHex = round(max_Xdeg_new/(2*r));
end

function hexCenters = computeHexCenters(x0, y0, rp, nMaxHex)

    % large radius
    %rp = round(Rp*sqrt(3)/2);

    Rp = round(rp*2/sqrt(3));
    hexCenters = cell(nMaxHex + 1, 1);
    hexCenters{1} = [x0 y0];
    for h = 1:nMaxHex
        % diagonal
        x_d = x0 + rp*(2*h:-1:h)';
        y_d = y0 + Rp*(0:1.5:1.5*h)';
    
        % horizontal
        xh_num = floor(h/2);
        xh_start = rem(h, 2);
        xh_end = xh_start + 2*(xh_num - 1);
        x_h = x0 + rp*(xh_start:2:xh_end)';
        y_h = y0 + Rp*ones(numel(x_h), 1)*3/2*h;
        hexCenters{h + 1} = [[x_d y_d]; [x_h y_h]];
    end
end
function hexCenters = removeMeridianCenters(inCell, removalType)
    hexCenters = inCell;
    nHexCenters = size(inCell, 1);

    switch removalType
        case 'all'
        % remove all hexagons on the meridian lines
            startFromRing = 1;
        case 'fix'
        % leaves center hexagon for fixation
        startFromRing = 2;
        case 'fov'
        % leave foveal (3 deg ring)
        startFromRing = 3;
    end

    for hc = startFromRing:nHexCenters
        currCenters = inCell{hc};
        outIdx = (currCenters(:, 1).*currCenters(:, 2))>0;
        newCenters = currCenters(outIdx, :);
        hexCenters{hc} = newCenters;
    end
end
