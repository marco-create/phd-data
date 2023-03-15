homeDir = pwd();
outDir = regexp(homeDir, '/', 'split');
subject = char(outDir(4));

try
    warning('Starting subject %s', subject)
    
   % Check that anatomy and inplane paths are correct
    s = load('mrSESSION.mat');
    ipPath = fullfile('Inplane','myInplane.nii');
    anatPath = fullfile('3DAnatomy','t1.nii');
    setVAnatomyPath(anatPath);
    % save the new paths
    mrGlobals;
    loadSession;
    mrSESSION = sessionSet(mrSESSION, 'Inplane Path', ipPath);
    saveSession;

    % Open inplane and gray views and set to Averages data types
    ip  = initHiddenInplane(); 
    vol = initHiddenGray();
    ip  = viewSet(ip,  'Current DataTYPE', 'Averages');
    vol = viewSet(vol, 'Current DataTYPE', 'Averages');

    % Check how many scans (in this case, should be two - ring and wedge)
    scans = 1:viewGet(ip, 'num scans');

    % Let's generate the experimental stimuli
    images_ring = load(fullfile('Stimuli', 'ring_images'), 'images');
    params_ring = load(fullfile('Stimuli', 'ring_params'), 'params');
    stimulus_ring = load(fullfile('Stimuli', 'ring_params'), 'stimulus');

    images_wedge = load(fullfile('Stimuli', 'wedge_images'), 'images');
    params_wedge = load(fullfile('Stimuli', 'wedge_params'), 'params');
    stimulus_wedge = load(fullfile('Stimuli', 'wedge_params'), 'stimulus');

    % Check prescan duration (if any) and tr
    disp(params_wedge.params.prescanDuration)
    disp(params_wedge.params.tr)
    disp(mrSESSION.functionals(1).keepFrames)

    % Let's view the stimulus for wedge and ring. Skip the prescan period. 
    % For frames per second, we will compute reciprocal of the difference
    % in frame to frame timing
    idx_wedge = stimulus_wedge.stimulus.seqtiming > params_wedge.params.prescanDuration;
    fps_wedge = round(1/median(diff(stimulus_wedge.stimulus.seqtiming)));
    % implay(images_wedge.images(:,:,stimulus_wedge.stimulus.seq(idx_wedge)), fps_wedge);

    idx_ring = stimulus_ring.stimulus.seqtiming > params_ring.params.prescanDuration;
    fps_ring = round(1/median(diff(stimulus_ring.stimulus.seqtiming)));
    % implay(images_ring.images(:,:,stimulus_ring.stimulus.seq(idx_ring)), fps_ring);

    % Open hidden gray view
    vw = initHiddenGray;
    % Get stimulus into dataTYPES
    vw = viewSet(vw, 'Current DataTYPE', 'Averages');

    % Load the ring parameter file. We want to check the stimulus size.
    % Other parameters will be read directly from this file by code.
    params_ring = load(fullfile('Stimuli', 'ring_params'), 'params');
    % Load the ring parameter file.
    params_wedge = load(fullfile('Stimuli', 'wedge_params'), 'params');

    % Set default retinotopy stimulus model parameters
    sParams = rmCreateStim(vw);    

    % Add relevant fields for ring
    sParams(1).stimType   = 'StimFromScan'; % this means the stimulus images will be read from a file
    sParams(1).stimSize   = 9.2;  % stimulus radius (in degrees visual angle) params_ring.radius
    sParams(1).nDCT       = 1;    % detrending frequeny maximum (cycles per scan): 1 means 3 detrending terms, DC (0 cps), 0.5 cps, and 1 cps  
    sParams(1).imFile     = fullfile('Stimulus', 'ring_images.mat'); % file containing stimulus images
    sParams(1).paramsFile = fullfile('Stimulus', 'ring_params.mat'); % file containing stimulus parameters
    sParams(1).imFilter   = 'thresholdedBinary'; % when reading in images, treat any pixel value different from background as a 1, else 0
    sParams(1).hrfType    = 'two gammas (SPM style)'; % we switch from the default, positive-only Boynton hRF to the biphasic SPM style
    sParams(1).prescanDuration = params_ring.params.prescanDuration/params_ring.params.framePeriod; % pre-scan duration will be stored in frames for the rm, but was stored in seconds in the stimulus file
    % Add relevant fields for wedge
    sParams(2).stimType   = 'StimFromScan'; % this means the stimulus images will be read from a file
    sParams(2).stimSize   = 9.2;  % stimulus radius (in degrees visual angle) params_ring.radius
    sParams(2).nDCT       = 1;    % detrending frequeny maximum (cycles per scan): 1 means 3 detrending terms, DC (0 cps), 0.5 cps, and 1 cps  
    sParams(2).imFile     = fullfile('Stimulus', 'wedge_images.mat'); % file containing stimulus images
    sParams(2).paramsFile = fullfile('Stimulus', 'wedge_params.mat'); % file containing stimulus parameters
    sParams(2).imFilter   = 'thresholdedBinary'; % when reading in images, treat any pixel value different from background as a 1, else 0
    sParams(2).hrfType    = 'two gammas (SPM style)'; % we switch from the default, positive-only Boynton hRF to the biphasic SPM style
    sParams(2).prescanDuration = params_wedge.params.prescanDuration/params_wedge.params.framePeriod; % pre-scan duration will be stored in frames for the rm, but was stored in seconds in the stimulus file

    n = viewGet(vw, 'Current DataTYPE');
    dataTYPES(n).retinotopyModelParams = [];
    dataTYPES(n) = dtSet(dataTYPES(n), 'rm stim params', sParams);
    saveSession();

    % Check it
    vw = rmLoadParameters(vw);
%     [~, M] = rmStimulusMatrix(viewGet(vw, 'rm params'));

    % Define some variables
    roiFileName = 'Occip_right'; % 'Occip_left' or 'Occip_right'
    searchType  = 'coarse to fine';
    vw = loadROI(vw, roiFileName);

    %% Run the pRF model
    % This might take several hours
    vw = rmMain(vw, roiFileName, searchType, ...
        'model', {'onegaussian'}, 'matFileName',strcat('rmOneGaussian_masked_',roiFileName));
    %% Clean up
    close all;
    mrvCleanWorkspace; 
    
    cd(homeDir)
catch
    fprintf('%s did not run', subject)
end