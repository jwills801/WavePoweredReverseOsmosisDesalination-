%%
pump1Duty= 0.40; pump2Duty = 0; out = sim('SCADA\devCode\velDutyRespTest.slx'); save(['Data\velDutyResp_2025Oct\velDutyRespTest_',num2str(pump1Duty*100,2),'_',num2str(pump2Duty*100,2)])

%%
pump1Duty= -0.0; pump2Duty = -0.; out = sim('SCADA\velDutyRespTest_neg'); save(['noiseTest'])
%% noise analysis
X = out.pos.Data;
t = out.pos.Time;        % Time vector            
T = t(2)-t(1);             % Sampling period
Fs = 1/T;            % Sampling frequency
L = numel(t);             % Length of signal

Y = fft(X);

hold on
plot(Fs/L*(0:L-1),abs(Y),"LineWidth",3)
title("Complex Magnitude of fft Spectrum")
xlabel("f (Hz)")
ylabel("|fft(X)|")
