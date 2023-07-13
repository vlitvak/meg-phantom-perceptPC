% Example script to reproduce the spectral plots shown in the paper
%
% Combining Magnetoencephalography with Telemetric Streaming of Intracranial 
% Recordings and Deep Brain Stimulation – a Feasibility Study
% By M. Fahimi Hnazaee, M. Sure, G. O'Neill, G. Leogrande, A. Schnitzler, E. Florin, V. Litvak

% Vladimir Litvak v.litvak@ucl.ac.uk
% Copyright (C) 2023 Wellcome Centre for Human Neuroimaging

spm('defaults', 'eeg');

dataroot = pwd;


conditions = {
    '01EmptyRoom'
    '02IPGoffNoMov'
    '03IPGoffMov'
    '04BipolarStimNoMov'
    '05BipolarStimMov'
    '06MonopolarStimNoMov'
    '07MonopolarStimMov'
    '08IndefiniteStreamingSensightNoMov'
    '09IndefiniteStreamingSensightMov'
    '10IndefiniteStreamingLegacyNoMov'
    '11IndefiniteStreamingLegacyMov'
    '12BrainSenseOffSensightNoMov'
    '13BrainSenseOffSensightMov'
    '14BrainSenseOffLegacyNoMov'
    '15BrainSenseOffLegacyMov'
    '16BrainSenseOnSensightNoMov'
    '17BrainSenseOnSensightMov'
    '18BrainSenseOnLegacyNoMov'
    '19BrainSenseOnLegacyMov'
    '20BrainSenseOn0AmpSensightNoMov'
    '21BrainSenseOn0AmpSensightMov'
    '22BrainSenseOn0AmpLegacyNoMov'
    '23BrainSenseOn0AmpLegacyMov'
    '24OpenTelemetrySensight'
    '25OpenTelemetryLegacy'
    };


condind = 1;
system = 'CTF';%'CTF' 'OPM' 'MEGIN'
%%
switch system
    case 'MEGIN'

        dataset = char(spm_select('FPList',fullfile(dataroot, system, 'sub-PhantomPerceptPC', 'meg'), ['^sub.*' conditions{condind} '.*.fif']));

        if isempty(dataset)
            error('No MEGIN data for this condition');
        end

        S = [];
        S.dataset = dataset;
        S.mode = 'continuous';
        S.checkboundary = 0;
        S.channels = {'MEG', 'MEGPLANAR'};
        D = spm_eeg_convert(S);

        S = [];
        S.D = D;
        S.mode = 'mark';
        S.badchanthresh = 0.8;
        S.methods(1).channels = {'MEGMAG'};
        S.methods(1).fun = 'flat';
        S.methods(1).settings.threshold = 1e-010;
        S.methods(1).settings.seqlength = 10;
        S.methods(2).channels = {'MEGPLANAR'};
        S.methods(2).fun = 'flat';
        S.methods(2).settings.threshold = 0.1;
        S.methods(2).settings.seqlength = 10;

        S.methods(3).channels = {'MEGMAG'};

        S.methods(3).fun = 'jump';

        S.methods(3).settings.threshold = 50000;

        S.methods(3).settings.excwin = 2000;
        S.methods(4).channels = {'MEGPLANAR'};
        S.methods(4).fun = 'jump';
        S.methods(4).settings.threshold = 5000;
        S.methods(4).settings.excwin = 2000;

        D = spm_eeg_artefact(S);
        delete(S.D);

        S = [];
        S.D = D;
        S.trialength = 3000;
        S.conditionlabels = 'phantom';
        S.bc = 0;
        D = spm_eeg_epochs(S);
        delete(S.D);


        S = [];
        S.D = D;
        S.badchanthresh = 0.2;
        S.methods(1).fun = 'events';
        S.methods(1).channels = 'all';
        S.methods(1).settings.whatevents.artefacts = 1;
        D = spm_eeg_artefact(S);
        delete(S.D);

        S = [];
        S.D = D;
        D = spm_eeg_remove_bad_trials(S);
        delete(S.D);

        D = badchannels(D, ':', 0);save(D);

        S=[];
        S.D=D;
        S.plot=1;
        S.channels= setdiff(D.chanlabels(D.indchantype('MEGMAG', 'GOOD')), {'MEG2441', 'MEG2231', 'MEG1711'});
        S.constant = 100;
        [p,f] = spm_opm_psd(S);
        ylim([1,1e4]);
        xlim([0 200]);

        S=[];
        S.D=D;
        S.plot=1;
        S.channels= setdiff(D.chanlabels(D.indchantype('MEGPLANAR', 'GOOD')), {'MEG2232', 'MEG2233' 'MEG2442', 'MEG2443'});
        S.constant = 0.6;
        S.units = 'fT/mm';
        [p,f] = spm_opm_psd(S);
        ylim([0.1,1e4]);
        xlim([0 200]);       
    case 'OPM'

        dataset = char(spm_select('FPList',fullfile(dataroot, system, 'sub-PhantomPerceptPC', 'meg'), ['^sub.*' conditions{condind} '.*.bin']));

        S= [];
        S.data= dataset;
        D1 = spm_opm_create(S);
        Yinds = setdiff(selectchannels(D1,'regexp_(G2.*)'), indchannel(D1, 'G2-DH-Y'));

        S=[];
        S.D=D1;
        S.plot=1;
        S.channels=chanlabels(D1,Yinds);
        S.constant = 30;
        S.triallength=3000;
        [p,f] = spm_opm_psd(S);
        ylim([1,1e4])
        xlim([0 200])

    case 'CTF'
        dataset = char(spm_select('FPList',fullfile(dataroot, system, 'sub-PhantomPerceptPC', 'meg'), 'dir', ['^sub.*' conditions{condind} '.*.ds']));

        S = [];
        S.dataset = dataset;
        S.mode = 'continuous';
        S.checkboundary = 0;
        S.channels = 'MEG';
        D = spm_eeg_convert(S);

        S=[];
        S.D=D;
        S.plot=1;
        S.channels= D.chanlabels;
        S.triallength=3000;
        S.constant = 5;
        [p,f] = spm_opm_psd(S);
        ylim([1,1e4]);
        xlim([0 200]);
end

delete(D);