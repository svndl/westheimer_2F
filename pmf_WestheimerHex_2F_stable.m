function pmf_WestheimerHex_2F_stable( varargin )
%
%	xDiva Matlab Function paradigm

%	"pmf_" prefix is not strictly necessary, but helps to identify
%	functions that are intended for this purpose.

%   Each Matlab Function paradigm will have its own version of this file

%	First argument is string for selecting which subfunction to use
%	Additional arguments as needed for each subfunction

%	Each subfunction must conclude with call to "assignin( 'base', 'output', ... )",
%	where value assigned to "output" is a variable or cell array containing variables
%	that xDiva needs to complete the desired task.

if nargin > 0, aSubFxnName = varargin{1}; else error( 'pmf_WestheimerHex_2F_stable.m called with no arguments' ); end

% these next three are shared by nested functions below, so we create
% them in this outermost enclosing scope.
definitions = MakeDefinitions;
parameters = {};
timing = {};
videoMode = {};

% some useful functional closures...
CFOUF = @(varargin) cellfun( varargin{:}, 'uniformoutput', false );
AFOUF = @(varargin) arrayfun( varargin{:}, 'uniformoutput', false );

%lambda functions
PVal = @( iPart, x ) ParamValue( num2str(iPart), x );
PVal_S = @(x) ParamValue( 'S', x );



% PVal_B = @(x) ParamValue( 'B', x );
% PVal_1 = @(x) ParamValue( 1, x );
% PVal_2 = @(x) ParamValue( 2, x );

aaFactor = 8;
ppath = setPathParadigm;

try
    switch aSubFxnName
        case 'GetDefinitions', GetDefinitions;
        case 'ValidateParameters', ValidateParameters;
        case 'MakeMovie', MakeMovie;
    end
catch tME
    errLog = fopen(fullfile(ppath.log, 'ErrorLog.txt'), 'a+');
    display(tME.message);
    for e = 1: numel(tME.stack)
        fprintf(errLog, ' %s ', tME.stack(e).file);
        fprintf(errLog, ' %s ', tME.stack(e).name);
        fprintf(errLog, ' %d\n', tME.stack(e).line);
    end
    fclose(errLog);
    rethrow( tME ); % this will be caught by xDiva for runtime alert message
end

    function rV = ParamValue( aPartName, aParamName )
        % Get values for part,param name strings; e.g "myViewDist = ParamValue( 'S', 'View Dist (cm)' );"
        tPart = parameters{ ismember( { 'S' 'B' '1' '2' }, {aPartName} ) }; % determine susbscript to get {"Standard" "Base" "Part1" "Part2"} part cell from parameters
        rV = tPart{ ismember( tPart(:,1), { aParamName } ), 2 }; % from this part, find the row corresponding to aParamName, and get value from 2nd column
    end
    function rV = GetParamArray( aPartName, aParamName )
        
        % For the given part and parameter name, return an array of values
        % corresponding to the steps in a sweep.  If the requested param is
        % not swept, the array will contain all the same values.
        
        % tSpatFreqSweepValues = GetParamArray( '1', 'Spat Freq (cpd)' );
        
        % Here's an example of sweep type specs...
        %
        % definitions{end-2} =
        % 	{
        % 		'Fixed'         'constant'   { }
        % 		'Contrast'      'increasing' { { '1' 'Contrast (pct)' } { '2' 'Contrast (pct)' } }
        % 		'Spat Freq'      'increasing' { { '1' 'Spat Freq (cpd)' } { '2' 'Spat Freq (cpd)' } }
        % 	}
        
        T_Val = @(x) timing{ ismember( timing(:,1), {x} ), 2 }; % get the value of timing parameter "x"
        tNCStps = T_Val('nmbCoreSteps');
        tSweepType = PVal_S('Sweep Type');
        
        % we need to construct a swept array if any of the {name,value} in definitions{5}{:,3}
        
        [ ~, tSS ] = ismember( tSweepType, definitions{end-2}(:,1) ); % the row subscript in definitions{5} corresponding to requested sweep type
        % determine if any definitions{5}{ tSS, { {part,param}... } } match arguments tPartName, tParamName
        IsPartAndParamMatch = @(x) all( ismember( { aPartName, aParamName }, x ) );
        tIsSwept = any( cellfun( IsPartAndParamMatch, definitions{end-2}{tSS,3} ) ); % will be false for "'Fixed' 'constant' { }"
        
        if ~tIsSwept
            rV = ones( tNCStps, 1 ) * ParamValue(  aPartName, aParamName );
        else
            tStepType = PVal_S('Step Type');
            tIsStepLin = strcmpi( tStepType, 'Lin Stair' );
            tSweepStart = PVal_S('Sweep Start');
            tSweepEnd = PVal_S('Sweep End');
            if tIsStepLin
                rV = linspace( tSweepStart, tSweepEnd, tNCStps )';
            else
                rV = logspace( log10(tSweepStart), log10(tSweepEnd), tNCStps )';
            end
        end
        
    end

    function rV = MakeDefinitions
        % for "ValidateDefinition"
        % - currently implementing 'integer', 'double', 'nominal'
        % - types of the cells in each parameter row
        % - only "standard" type names can be used in the "type" fields
        % - 'nominal' params should have
        %       (a) at least one item
        %		(b) value within the size of the array
        % - all other params (so far) should have empty arrays of items
        
        rV = { ...
            
        % - Parameters in part_S must use standard parameter names
        % - 'Sweep Type' : at least 'Fixed' sweep type must be defined as first item in list
        % - 'Modulation' : at least 'None' modulation type must be defined
        % - 'Step Type'  : at least 'Lin Stair' type must be defined,
        %                  first 4 step types are reserved, custom step types can only be added after them
        
        % "Standard" part parameters - common to all paradigms, do not modify names.
        {
        'View Dist (cm)'                    70.0	        'double'   {}
        'Mean Lum (cd)'                     51.0	        'double'   {} % under default calibration, this is (0.5,0.5,0.5)
        'Fix Point'                         'None'	        'nominal'  { 'None' 'Cross' }
        %'Sweep Type'                       'Pedestal Size' 'nominal'  { 'Fixed' 'Pedestal Size' 'Probe Contrast' }
        %'Sweep Type'                       'Fixed'         'nominal'  { 'Fixed', 'Probe Contrast' }        
        'Sweep Type'                        'Fixed'         'nominal'  { 'Fixed' }                
        'Step Type'                         'Lin Stair'	    'nominal'  { 'Lin Stair', 'Log Stair' }
        'Sweep Start'                       0.0	            'double'   {}
        'Sweep End'                         1.0             'double'   {}
        'Modulation'                        'Sawtooth-off'  'nominal'  { 'Sawtooth-on', 'Sawtooth-off'} %
        }
        %
        
        % "Base" part parameters - paradigm specific parameters that apply to unmodulated parts of the stimulus
        {
        'ModInfo'                           0.0             'integer'  {}
        'Stimulus Extent'                   'Fullscreen'	'nominal'  {'Fullscreen', 'Square'} % 'SqrOnBlack' 'SqrOnMean' could be included as memory intense as 'Fullscreen'        
        'Bgr Lum (cd)'                      11              'double'  {} 
        'Pedestal Lum (cd)'                 51              'double'  {} 
        'Base Element Size (amin)'          20.0            'double'   {}
        'Pedestal Size (% base)'            100             'double'   {}                
		'Magnification Factor'              0.7             'double'   {}      
        }
        
        % "Part1" - parameters that apply to part of stimulus that carries first frequency tag.
        % "Cycle Frames" must be first parameter
        {
        'Cycle Frames'                      16          'integer'      {}  % framerate(Hz)/stimFreq(Hz) Modulation frequency every other frame (2 Hz)
        'Contrast (% ped)'                20.0        'double'       {}
        'Contrast Excursion'                'Above'     'nominal'      {'Above', 'Below', 'Symmetric'}        
        'Probe Size (% base)'               20          'double'       {}
        'Probe Fov/Per'                     'All'       'nominal'      {'All', 'Fov', 'Per'}
        'Horizontal VF'                     'Upper'     'nominal'      {'All', 'Upper', 'Lower'}
        'Vertical VF'                       'All'       'nominal'      {'All', 'Left', 'Right'}
         }
        
        % "Part2" - parameters that apply to part of stimulus that carries second frequency tag.
        % "Cycle Frames" must be first parameter
         
        {
        'Cycle Frames'                      20          'integer'      {}  % framerate(Hz)/stimFreq(Hz) Modulation frequency every other frame (2 Hz)
        'Contrast (% ped)'                  20.0        'double'       {}
        'Contrast Excursion'                '-'         'nominal'      {'-'}
        'Probe Size (% base)'               20          'double'       {}
        'Probe Fov/Per'                     'All'       'nominal'      {'All', 'Fov', 'Per'}
        'Horizontal VF'                     'Lower'     'nominal'      {'All', 'Upper', 'Lower'}
        'Vertical VF'                       'All'       'nominal'      {'All', 'Left', 'Right'}
         }
        
        % Sweepable parameters
        % The cell array must contain as many rows as there are supported Sweep Types
        % 1st column (Sweep Types) contains Sweep Type as string
        % 2nd column (Stimulus Visiblity) contains one of the following strings,
        % indicating how stimulus visibility changes when corresponding swept parameter value increases:
        %   'constant' - stimulus visibility stays constant
        %   'increasing' - stimulus visibility increases
        %   'decreasing' - stimulus visibility decreases
        % 3rd column contains a single-row cell array of pairs, where each pair is a single-row cell
        % array of 2 strings: { Part name, Parameter name }
        
        % If sweep affects only one part, then you only need one
        % {part,param} pair; if it affects both parts, then you need both
        % pairs, e.g. for "Contrast" and "Spat Freq" below
        
        {
        'Fixed'			   'constant'   { }
        %'Pedestal Size'    'constant' { { 'B' 'Pedestal Size (amin)' } }
%         'Probe Contrast'   'increasing' { { '1' 'Contrast min (pct)' } {'1' 'Contrast max (pct)'} ...
%             { '2' 'Contrast min (pct)' } {'2' 'Contrast max (pct)'} }
        }        
        
        % ModInfo information
        % The cell array must contain as many rows as there are supported Modulations
        % 1st column (Modulation) contains one of the supported Modulation typs as string
        % 2nd column contains the name of the ModInfo parameter as string
        % 3rd column (default value) contains default value of the ModInfo
        % parameter for this Modulation
        {        
         'Sawtooth-on'      'ModInfo'          0.0
         'Sawtooth-off'     'ModInfo'          0.0         
         }
        % Required by xDiva, but not by Matlab Function
        {
        'Version'					1
        'Adjustable'				true
        'Needs Unique Stimuli'		false % ###HAMILTON for generating new stimuli every time
        'Supports Interleaving'		false
        'Part Name'                 { 'Frequency I', 'Frequency II' }
        'Frame Rate Divisor'		{ 2 1 } % {even # frames/cycle only, allows for odd-- makes sense for dot update}
        'Max Cycle Frames'			{ 120 120 } % i.e. -> 0.5 Hz, 10 Hz
        'Allow Static Part'			{ true true }
        }
        };
    end

    function GetDefinitions
        assignin( 'base', 'output', MakeDefinitions );
    end

    function ValidateParameters
        % xDiva invokes Matlab Engine command:
        
        % pmf_<subParadigmName>( 'ValidateParameters', parameters, timing, videoMode );
        % "parameters" here is an input argument. Its cellarray hass the
        % same structure as "defaultParameters" but each parameter row has only first two
        % elements
        
        % The "timing" and "videoMode" cellarrays have the same row
        % structure with each row having a "name" and "value" elements.
        
        
        [ parameters, timing, videoMode ] = deal( varargin{2:4} );
 
        %% get video system info
                
        VMVal = @(x) videoMode{ ismember( videoMode(:,1), {x} ), 2 };
        
        width_pix = VMVal('widthPix');
        height_pix = VMVal('heightPix');        
        minDim = width_pix;
        
        width_cm = VMVal('imageWidthCm');
        viewDistCm = PVal('S','View Dist (cm)');
        width_deg = 2 * atand( (width_cm/2)/viewDistCm );
        pix2arcmin = ( width_deg * 60 ) / width_pix;
        
        %% Standard output routine
        validationMessages = {};
        
        ValidateElementsSizes;
        ValidateElementsBrightness;
        ValidateElementActivationLogic;
        
        parametersValid = isempty( validationMessages );
        output = { parametersValid, parameters, validationMessages };
        assignin( 'base', 'output', output );
        
        %% Correct/Message functions
        
        function CorrectParam( aPart, aParam, aVal )
            tPartLSS = ismember( { 'S' 'B' '1' '2' }, {aPart} );
            tParamLSS = ismember( parameters{ tPartLSS }(:,1), {aParam} );
            parameters{ tPartLSS }{ tParamLSS, 2 } = aVal;
        end
        
        function AppendVMs(aStr), validationMessages = cat(1,validationMessages,{aStr}); end
        
        
        %% Begin validation definition
                
        function ValidateElementsSizes
            baseSize_amin = PVal('B', 'Base Element Size (amin)');
            pedestalSize_pct = GetParamArray('B', 'Pedestal Size (% base)');            
            probeSize_pct(1) = PVal('1', 'Probe Size (% base)');        
            probeSize_pct(2) = PVal('2', 'Probe Size (% base)');    
                 
            % 1. Validate base element size: at least width_pix 
            baseSize_deg = baseSize_amin/60.0;
            if (baseSize_deg > width_deg*.05)
                newbaseSize_amin = 20;
                
                CorrectParam('B', 'Base Element Size (amin)', newbaseSize_amin);
                AppendVMs(sprintf('Requested Base elem size is out of range, correcting to default %.1f amin', ...
                   newbaseSize_amin)); 
            end
                
            % 2. Validate and correct % values to be in [1, 100] range
            % probe size depends on base only 
            if (probeSize_pct(1) > 100 || probeSize_pct(1) <= 0)
                newprobeSize_pct = 20;
                
                CorrectParam('1', 'Probe Size (% base)', newprobeSize_pct);
                AppendVMs(sprintf('Requested probe size in Part %d is out of range, correcting to default % %.1f', ...
                   1, newprobeSize_pct)); 
            end
            
            if (probeSize_pct(2) > 100 || probeSize_pct(2) <= 0)
                newprobeSize_pct = 20;
                CorrectParam('2', 'Probe Size (% base)', newprobeSize_pct);
                AppendVMs(sprintf('Requested probe size in Part %d is out of range, correcting to default % %.1f', ...
                   2, newprobeSize_pct)); 
            end
            
            %3. Validate pedestal range
            
            outOfRange_bool = (pedestalSize_pct > 100) | (pedestalSize_pct <= 0);
            if (any(outOfRange_bool))
                newPdestalSize_pct = 100;
                CorrectParam('B', 'Pedestal Size (% base)', newPdestalSize_pct);
                AppendVMs(sprintf('Requested Pedestal size size is out of range, correcting to default %.1f', ...
                   newPdestalSize_pct)); 
            end                 
        end
        % Validate elements brightness
        function ValidateElementsBrightness
            minLuminance__Cd = VMVal('minLuminanceCd');
            maxLuminance_Cd = VMVal('maxLuminanceCd');
        
            requested_bgrLuminance_Cd = PVal('B', 'Bgr Lum (cd)' );
            requested_pedLuminance_Cd = PVal('B', 'Pedestal Lum (cd)');
            
            probeLum_pct(:, 1) = GetParamArray('1', 'Contrast (% ped)');
            probeLum_pct(:, 2) = GetParamArray('2', 'Contrast (% ped)');
            
            % 1. Verify pedestal range:  minLuminanceCd < Pedestal Luminance <maxLuminanceCd
            
            if (requested_pedLuminance_Cd >= maxLuminance_Cd || requested_pedLuminance_Cd <= minLuminance__Cd)
                
                newPedLum_Cd = 51;
                CorrectParam('B', 'Pedestal Lum (cd)' , newPedLum_Cd);
                AppendVMs(sprintf('Requested pedestal luminance is out of range, correcting to default % %.1f cd', ...
                    newPedLum_Cd));
            end
            
            % 2. Verify background range:  minLuminanceCd < Background Luminance <maxLuminanceCd
            
            if (requested_bgrLuminance_Cd >= maxLuminance_Cd || requested_bgrLuminance_Cd <= minLuminance__Cd)
                
                newBgrLum_Cd = 11;
                CorrectParam('B', 'Bgr Lum (cd)' , newBgrLum_Cd);
                AppendVMs(sprintf('Requested background luminance is out of range, correcting to default % %.1f cd', ...
                    newBgrLum_Cd));
            end
            
            % 3. Verify background-pedestal relationship:  Background Luminance < Pedestal Luminance
            if (requested_bgrLuminance_Cd >= requested_pedLuminance_Cd)
                newBgrLum_Cd = requested_pedLuminance_Cd*0.2;
                CorrectParam('B', 'Bgr Lum (cd)' , newBgrLum_Cd);
                AppendVMs(sprintf('Requested bgr luminance is greater than pedestal, correcting to default 20% %.1f cd', ...
                    newBgrLum_Cd));
            end
            
            % 4. Verify probe contrast range [>0]
            if (any(probeLum_pct(:, 1) < 0))
                newprobeLum_pct_1 = 20;
                CorrectParam('1', 'Contrast (% ped)', newprobeLum_pct_1);
                AppendVMs(sprintf('Requested probe luminance in Part %d cannot be negative, correcting to default', ...
                    1));
            end
            if (any(probeLum_pct(:, 2) < 0))
                newprobeLum_pct_2 = 20;
                CorrectParam('2', 'Contrast (% ped)', newprobeLum_pct_2);
                AppendVMs(sprintf('Requested probe luminance in Part %d cannot be negative, correcting to default', ...
                    2));
            end            
        
        end 
        % validate activcation logic
        function ValidateElementActivationLogic
            % the objective of this validation is to check if there's any
            % overlap in probe flicker
            
            % pull values from FI, FII
            probeFovPer{1} = PVal('1', 'Probe Fov/Per');
            probeFovPer{2} = PVal('2', 'Probe Fov/Per');
            
            probeHF{1} = PVal('1', 'Horizontal VF');    
			probeHF{2} = PVal('2', 'Horizontal VF');    

            probeHS{1} = PVal('1', 'Vertical VF');            
            probeHS{2} = PVal('2', 'Vertical VF');

            % 
            overlap_probeFovPer = sum(ismember(probeFovPer, 'All')); 
            overlap_probeHF = sum(ismember(probeHF, 'All'));
            overlap_probeHS = sum(ismember(probeHS, 'All'));
            
            n_overlaps = overlap_probeFovPer + overlap_probeHF + overlap_probeHS;
            
            same_probeFovPer = probeFovPer{1} == probeFovPer{2};
            same_probeHF = probeHF{1}== probeHF{2};
            same_probeHS = probeHS{1} == probeHS{2};
            
            n_same = same_probeFovPer + same_probeHF + same_probeHS;
            
            
            % overlaying will occur in the following situation:
            
            % 3 fields are the same: n_same == 3
            % 3 fields overlap: n_overlaps == 3
            % There's 1 overlap and 2 same values
            % There are 2 overlaps and 1 same value
            
            if (n_overlaps + n_same == 3)
                AppendVMs(sprintf('The flicker spatial configuration will generate an overlap, changing to default..'));
                
                CorrectParam('1', 'Probe Fov/Per', 'All');
                CorrectParam('2', 'Probe Fov/Per', 'All');
                CorrectParam('1', 'Horizontal VF', 'Upper');
                CorrectParam('2', 'Horizontal VF', 'Lower');
                
                CorrectParam('1', 'Vertical VF', 'All');
                CorrectParam('2', 'Vertical VF', 'All');
            end                
           
        end
    end%% endof validation block
    function MakeMovie
        % ---- GRAB & SET PARAMETERS ----
        [ parameters, timing, videoMode, trialNumber ] = deal( varargin{2:5} );
        save(fullfile(ppath.home,'pmf_WestheimerHex_MakeMovie_2F_stable.mat'), 'parameters', 'timing', 'videoMode');
        TRVal = @(x) timing{ ismember( timing(:,1), {x} ), 2 };
        VMVal = @(x) videoMode{ ismember( videoMode(:,1), {x} ), 2 };
        
        needsUnique = definitions{end}{3,2};
        needsImFiles = true;
        preludeType = {'Dynamic', 'Blank', 'Static'};
        % timing/trial control vars
        parameters_timing.nCoreSteps = TRVal('nmbCoreSteps');
        parameters_timing.nCoreBins = TRVal('nmbCoreBins');
        parameters_timing.nPreludeBins = TRVal('nmbPreludeBins');
        parameters_timing.framesPerStep = TRVal('nmbFramesPerStep');
        parameters_timing.framesPerBin = TRVal('nmbFramesPerBin');
        parameters_timing.preludeType = preludeType{1 + TRVal('preludeType')};
        parameters_timing.isBlankPrelude = parameters_timing.preludeType == 1;
        parameters_timing.nCoreFrames = parameters_timing.framesPerStep * parameters_timing.nCoreSteps;
        parameters_timing.nPreludeFrames = parameters_timing.nPreludeBins * parameters_timing.framesPerBin;
        parameters_timing.nTotalFrames = 2 * parameters_timing.nPreludeFrames + parameters_timing.nCoreFrames;
        
		parameters_timing.updateFramesPerCycle(1) = PVal(1, 'Cycle Frames'); % part 1 = Frequency F1
        parameters_timing.updateFramesPerCycle(2) = PVal(2, 'Cycle Frames'); % part 2 = Frequency F2
		
        
        % screen vars
        parameters_video.width_pix = VMVal('widthPix');
        parameters_video.height_pix = VMVal('heightPix');
        parameters_video.width_cm = VMVal('imageWidthCm');
        parameters_video.height_cm = VMVal('imageHeightCm');
        parameters_video.frameRate = VMVal('nominalFrameRateHz');
        parameters_video.minLuminanceCd = VMVal('minLuminanceCd');
        parameters_video.maxLuminanceCd = VMVal('maxLuminanceCd');
        parameters_video.meanLuminanceCd = VMVal('meanLuminanceCd');
        parameters_video.meanLuminanceBitmap = VMVal('meanLuminanceBitmapValue');
        parameters_video.gammaTableCapacity = VMVal('gammaTableCapacity');
        
        parameters_video.viewDistCm = PVal('S','View Dist (cm)');
        parameters_video.aaFactor = aaFactor;
        
        % Standard
        parameters_stimulus.sweepType = PVal('S','Sweep Type');
        parameters_stimulus.isSwept = ~strcmp(parameters_stimulus.sweepType, 'Fixed');  
        parameters_stimulus.modType = PVal('S', 'Modulation');       
        parameters_stimulus.meanLum_cad = PVal('S', 'Mean Lum (cd)');
        
        % Base
        parameters_stimulus.bgrLum_cd = PVal('B', 'Bgr Lum (cd)' );
        parameters_stimulus.viewMode = PVal('B', 'Stimulus Extent');
        parameters_stimulus.pedestalLum_cd = PVal('B', 'Pedestal Lum (cd)');
        parameters_stimulus.mfactor = PVal('B', 'Magnification Factor');            
        parameters_stimulus.baseSize_amin = PVal('B', 'Base Element Size (amin)');
        parameters_stimulus.pedestalSize_pct = GetParamArray('B', 'Pedestal Size (% base)');
        
		%% Part 1 (F1)
		parameters_stimulus.probeSize_pct(1) = PVal('1', 'Probe Size (% base)');        
        parameters_stimulus.probeLum_pct(:, 1) = GetParamArray('1', 'Contrast (% ped)');
        parameters_stimulus.probeDirectionChange = PVal('1', 'Contrast Excursion');
        parameters_stimulus.probeFovPer{1} = PVal('1', 'Probe Fov/Per');

		%% Part 2 (F2)
		parameters_stimulus.probeSize_pct(2) = PVal('2', 'Probe Size (% base)');        
        parameters_stimulus.probeLum_pct(:, 2) = GetParamArray('2', 'Contrast (% ped)');
        parameters_stimulus.probeFovPer{2} = PVal('2', 'Probe Fov/Per');
		
        %% hemifields/hemispheres
		try
            parameters_stimulus.probeHF{1} = PVal('1', 'Horizontal VF');    
            parameters_stimulus.probeHS{1} = PVal('1', 'Vertical VF');
			parameters_stimulus.probeHF{2} = PVal('2', 'Horizontal VF');    
            parameters_stimulus.probeHS{2} = PVal('2', 'Vertical VF');
        catch err
            parameters_stimulus.probeHF{1} = 'All';    
            parameters_stimulus.probeHS{1} = 'All';            
            parameters_stimulus.probeHF{2} = 'All';    
            parameters_stimulus.probeHS{2} = 'All';            
		end
        save(fullfile(ppath.home,'hexWestheimerInput_2F_stable.mat'), 'parameters_stimulus', 'parameters_video', 'parameters_timing');
        
        [rImSeq, rIms] = westheimerHex_2F_stable(parameters_stimulus, parameters_video, parameters_timing);
        save(fullfile(ppath.home, 'hexWestheimerOutput_2F_stable.mat'), 'rImSeq', 'rIms');
                
        isSuccess = true;
        output = { isSuccess, rIms, cast( rImSeq, 'int32') }; % "Images" (single) and "Image Sequence" (Int32)
        %clear rIms
        assignin( 'base', 'output', output )
    end
end

 
