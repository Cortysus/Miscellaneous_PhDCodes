clear variables;close all
%% Constants
T = 298;
eta = 0.0008872; %Fluid viscosity (in Pa.s)
kB = 1.38*10^(-23);
R = 0.115e-6; %Bead radius
rho_p = 1.04; %Bead density (in g/cm^3)
rho_f = 1.00; %Fluid intensity (in g/cm^3)
m_p = 1e3*rho_p*(4/3)*pi*R^3; %Bead mass (in Kg)
m_f = 1e3*rho_f*(4/3)*pi*R^3; %Displaced fluid mass (in Kg)
D0 = (kB*T)/(6*pi*R*eta);
J0 = (pi*R)/(kB*T);
t = logspace(-6,1,300)';



%% Test 1: H2O
MSD = 6 * D0 * t; % 3D diffusivity
dMSD = 6 * D0 * ones(length(t),1);
figure(1)
yyaxis left
loglog(t,MSD)
yyaxis right
loglog(t,dMSD)

dMSD_Fit = dMSD;
t_Fit = t;
t_Fit(dMSD_Fit<1e-16)=[];
dMSD_Fit(dMSD_Fit<1e-16)=[];

% Parameters specification:
Ng = 161;
Nl = 1;
ILT_Input.Iquad = 2;      % Simpson's rule
ILT_Input.Igrid = 2;      % Log grid
ILT_Input.Kernel = 1;     % ILT Kernel
ILT_Input.Nnq = 0;        
ILT_Input.Anq = 0;
ILT_Input.Neq = 0;
ILT_Input.Aeq = 0;
ILT_Input.Nneg = 1;       % Non-negativity constraint
ILT_Input.Ny0 = 0;        % y(0)=1 condition
ILT_Input.iwt = 1;        % Unweighted analysis
ILT_Input.alpha_lims = [0.01,100];
ILT_Input.Nbg = 1;

[s,g,yfit,lambda,info] = CRIE(t_Fit,dMSD_Fit,Ng,Nl,ILT_Input);

bg_term = s(end);
fit_term = info.A(:,1:end-1)*s(1:end-1);

if all(abs(fit_term)./bg_term<1e-3) 
    s(1:end-1,:) = 0;
end
s = abs(s);
Om = logspace(log10(1/t(end-3)),log10(1/t(1)),100)';
[gM,~] = meshgrid(info.g,Om);
[cM,OmM] = meshgrid(info.c,Om);
A_Om = cM.*(log(10)*10.^(gM)).*1./(1i*OmM.*(10.^gM + 1i*OmM));
y_Om = A_Om*s(1:end-1) - s(end)./Om.^2;
G_Om = 3*kB*T./(3*pi*R*1i*Om.*y_Om);
%%
[OmMas,GMas]=MSDtoG_Mason(t,MSD,'R',115e-9,'CG',1.01,'T',T);
%%
[OmEv,GEv]=MSDtoG_Evans_oversampling(t,MSD,1e6,'R',115e-9,'CG',1.01,'T',T,'Beta',1,'Jfactor',J0);
%%
Colours = get(groot,'DefaultAxesColorOrder');
h1=loglog(Om,real(G_Om),'o','MarkerEdgeColor',Colours(1,:),'MarkerFaceColor',Colours(1,:));
hold on
h2=loglog(Om,imag(G_Om),'o','MarkerEdgeColor',Colours(1,:));
h3=loglog(OmMas,real(GMas),'s','MarkerEdgeColor',Colours(2,:),'MarkerFaceColor',Colours(2,:));
h4=loglog(OmMas,imag(GMas),'s','MarkerEdgeColor',Colours(2,:));
h5=loglog(OmEv,real(GEv),'h','MarkerEdgeColor',Colours(3,:),'MarkerFaceColor',Colours(3,:));
h6=loglog(OmEv,imag(GEv),'h','MarkerEdgeColor',Colours(3,:));
h7=loglog(Om,zeros(length(Om),1),'k-');
h8=loglog(Om,eta*Om,'k--');
hold off
xlabel('\omega [rad/s]')
ylabel('G'',G'''' [Pa]')
set(get(get(h1,'Annotation'),'LegendInformation'),'IconDisplayStyle','off');
set(get(get(h3,'Annotation'),'LegendInformation'),'IconDisplayStyle','off');
%set(get(get(h5,'Annotation'),'LegendInformation'),'IconDisplayStyle','off');
set(get(get(h7,'Annotation'),'LegendInformation'),'IconDisplayStyle','off');
legend('G''''  - KC','G''''  - Mason','G''  - Evans','G''''  - Evans','G''''  - Theory','Location','northwest')

%% Test 2: Viscoelastic Material
eta_Max = 500*eta;
G_Max = 1e2;
m_star = m_p + 0.5*m_f;
tau_p = m_star/(6*pi*eta*R);
tau_Max = eta_Max/G_Max;
Omega=sqrt(6*pi*G_Max*R/m_star - 0.25*(1/tau_Max - 1/tau_p)^2);
Damp_const = 0.5*(1/tau_Max + 1/tau_p); 
[MSD,~,dMSD] = Gen_Maxwell_fun(t,Omega,Damp_const,tau_Max,tau_p);
MSD = (3*kB*T/m_star)*MSD;
dMSD = (3*kB*T/m_star)*dMSD;
figure(1)
yyaxis left
loglog(t,MSD)
yyaxis right
loglog(t,dMSD)

dMSD_Fit = dMSD;
t_Fit = t;
t_Fit(dMSD_Fit<1e-16)=[];
dMSD_Fit(dMSD_Fit<1e-16)=[];

% Parameters specification:
Ng = 161;
Nl = 1;
ILT_Input.Iquad = 2;      % Simpson's rule
ILT_Input.Igrid = 2;      % Log grid
ILT_Input.Kernel = 1;     % ILT Kernel
ILT_Input.Nnq = 0;        
ILT_Input.Anq = 0;
ILT_Input.Neq = 0;
ILT_Input.Aeq = 0;
ILT_Input.Nneg = 1;       % Non-negativity constraint
ILT_Input.Ny0 = 0;        % y(0)=1 condition
ILT_Input.iwt = 1;        % Unweighted analysis
ILT_Input.alpha_lims = [0.01,100];
ILT_Input.Nbg = 1;

[s,g,yfit,lambda,info] = CRIE(t_Fit,dMSD_Fit,Ng,Nl,ILT_Input);
%%
bg_term = s(end);
fit_term = info.A(:,1:end-1)*s(1:end-1);

if all(abs(fit_term)./bg_term<1e-3) 
    s(1:end-1,:) = 0;
end
s = abs(s);
Om = logspace(log10(1/t(end-3)),log10(1/t(1)),100)';
[gM,~] = meshgrid(log10(info.g),Om);
[cM,OmM] = meshgrid(info.c,Om);
A_s = cM.*(log(10)*10.^(gM)).*1./(OmM.*(10.^gM + OmM));
A_Om = cM.*(log(10)*10.^(gM)).*1./(1i*OmM.*(10.^gM + 1i*OmM));
y_s = A_s*s(1:end-Nl) + s(end)./Om.^2;
y_Om = A_Om*s(1:end-1) - s(end)./Om.^2;
G_s = 3*kB*T./(3*pi*R*Om.*y_s);
G_Om = 3*kB*T./(3*pi*R*1i*Om.*y_Om);
%%
Gs_pp = csape(Om,G_s,'variational'); %Natural cubic spline
Om_d = diff(Om);
Gs_R = -2*Gs_pp.coefs(:,2).*Om_d;
Gs_I = -3*Gs_pp.coefs(:,1).*Om_d.^2  + Gs_pp.coefs(:,3);
GJ_d = @(x,etaI,GI,tauM) -1i.*etaI - 1i*((GI*tauM)./(1 - 1i*x*tauM).^2);
GJ = @(x,etaI,GI,tauM) -1i.*x.*(etaI + (GI*tauM)./(1 - 1i*x*tauM));
loglog(Om(3:end-1),Gs_R(2:end-1),Om(3:end-1),Gs_I(2:end-1),Om(2:end),diff(real(GJ(Om,eta,G_Max,tau_Max)))./Om_d,Om(2:end),diff(imag(GJ(Om,eta,G_Max,tau_Max)))./Om_d)
%%
m = 30;
A_f = zeros(length(Om),m);
for i=1:m
    A_f(:,i) = ((Om).^(i-1))./((Om + 1).^(i));
end
b_f = A_f\(y_s.*Om);
loglog(Om,y_s.*Om,Om,A_f*b_f)
%%
[OmMas,GMas]=MSDtoG_Mason(t,MSD,'R',115e-9,'CG',1.01,'T',T);
%%
[OmEv,GEv]=MSDtoG_Evans_oversampling(t,MSD,1e6,'R',115e-9,'CG',1.01,'T',T,'Beta',1,'Jfactor',J0);
%%
GJ = @(x,etaI,GI,tauM) -1i.*x.*(etaI + (GI*tauM)./(1 - 1i*x*tauM));
Colours = get(groot,'DefaultAxesColorOrder');
h1=loglog(Om,real(G_Om),'o','MarkerEdgeColor',Colours(1,:),'MarkerFaceColor',Colours(1,:));
hold on
h2=loglog(Om,imag(G_Om),'o','MarkerEdgeColor',Colours(1,:));
h3=loglog(OmMas,real(GMas),'s','MarkerEdgeColor',Colours(2,:),'MarkerFaceColor',Colours(2,:));
h4=loglog(OmMas,imag(GMas),'s','MarkerEdgeColor',Colours(2,:));
h5=loglog(OmEv,real(GEv),'h','MarkerEdgeColor',Colours(3,:),'MarkerFaceColor',Colours(3,:));
h6=loglog(OmEv,imag(GEv),'h','MarkerEdgeColor',Colours(3,:));
h7=loglog(Om,real(GJ(Om,eta,G_Max,tau_Max)),'k-');
h8=loglog(Om,-imag(GJ(Om,eta,G_Max,tau_Max)),'k--');

OmGuideLin1 = logspace(-1,1);
OmGuideLin2 = logspace(0,2);

loglog(OmGuideLin1,10000*eta*OmGuideLin1,'k--');
loglog(OmGuideLin2,0.1*eta*OmGuideLin2.^2,'k--');


hold off
xlabel('\omega [rad/s]')
ylabel('G'',G'''' [Pa]')
%set(get(get(h1,'Annotation'),'LegendInformation'),'IconDisplayStyle','off');
%set(get(get(h3,'Annotation'),'LegendInformation'),'IconDisplayStyle','off');
%set(get(get(h5,'Annotation'),'LegendInformation'),'IconDisplayStyle','off');
%set(get(get(h7,'Annotation'),'LegendInformation'),'IconDisplayStyle','off');
legend('G''  - KC','G''''  - KC','G'' - Mason','G''''  - Mason','G''  - Evans','G''''  - Evans','G''  - Theory','G''''  - Theory','Location','northwest')

%% Test 4: Viscoelastic Material (with Noise)

eta_Max = 500*eta;
G_Max = 1e2;
m_star = m_p + 0.5*m_f;
tau_p = m_star/(6*pi*eta*R);
tau_Max = eta_Max/G_Max;
Omega=sqrt(6*pi*G_Max*R/m_star - 0.25*(1/tau_Max - 1/tau_p)^2);
Damp_const = 0.5*(1/tau_Max + 1/tau_p); 
[MSD,~,~] = Gen_Maxwell_fun(t,Omega,Damp_const,tau_Max,tau_p);
MSD = (3*kB*T/m_star)*MSD;
for i = 1:length(MSD)
    MSD(i) = MSD(i) + rand(1)*MSD(i);
end

dMSD_Fit = dMSD;
t_Fit = t;
t_Fit(dMSD_Fit<1e-16)=[];
dMSD_Fit(dMSD_Fit<1e-16)=[];

% Parameters specification:
Ng = 161;
Nl = 1;
ILT_Input.Iquad = 2;      % Simpson's rule
ILT_Input.Igrid = 2;      % Log grid
ILT_Input.Kernel = 1;     % ILT Kernel
ILT_Input.Nnq = 0;        
ILT_Input.Anq = 0;
ILT_Input.Neq = 0;
ILT_Input.Aeq = 0;
ILT_Input.Nneg = 1;       % Non-negativity constraint
ILT_Input.Ny0 = 0;        % y(0)=1 condition
ILT_Input.iwt = 1;        % Unweighted analysis
ILT_Input.alpha_lims = [0.01,100];
ILT_Input.Nbg = 1;

[s,g,yfit,lambda,info] = CRIE(t_Fit,dMSD_Fit,Ng,Nl,ILT_Input);
%%
bg_term = s(end);
fit_term = info.A(:,1:end-1)*s(1:end-1);

if all(abs(fit_term)./bg_term<1e-3) 
    s(1:end-1,:) = 0;
end
s = abs(s);
Om = logspace(log10(1/t(end-3)),log10(1/t(1)),100)';
[gM,~] = meshgrid(log10(info.g),Om);
[cM,OmM] = meshgrid(info.c,Om);
A_s = cM.*(log(10)*10.^(gM)).*1./(OmM.*(10.^gM + OmM));
A_Om = cM.*(log(10)*10.^(gM)).*1./(1i*OmM.*(10.^gM + 1i*OmM));
y_s = A_s*s(1:end-Nl) + s(end)./Om.^2;
y_Om = A_Om*s(1:end-1) - s(end)./Om.^2;
G_s = 3*kB*T./(3*pi*R*Om.*y_s);
G_Om = 3*kB*T./(3*pi*R*1i*Om.*y_Om);

%%
[OmMas,GMas]=MSDtoG_Mason(t,MSD,'R',115e-9,'CG',1.01,'T',T);
%%
[OmEv,GEv]=MSDtoG_Evans_oversampling(t,MSD,1e6,'R',115e-9,'CG',1.01,'T',T,'Beta',1,'Jfactor',J0);
%%
GJ = @(x,etaI,GI,tauM) -1i.*x.*(etaI + (GI*tauM)./(1 - 1i*x*tauM));
Colours = get(groot,'DefaultAxesColorOrder');
h1=loglog(Om,real(G_Om),'o','MarkerEdgeColor',Colours(1,:),'MarkerFaceColor',Colours(1,:));
hold on
h2=loglog(Om,imag(G_Om),'o','MarkerEdgeColor',Colours(1,:));
h3=loglog(OmMas,real(GMas),'s','MarkerEdgeColor',Colours(2,:),'MarkerFaceColor',Colours(2,:));
h4=loglog(OmMas,imag(GMas),'s','MarkerEdgeColor',Colours(2,:));
h5=loglog(OmEv,real(GEv),'h','MarkerEdgeColor',Colours(3,:),'MarkerFaceColor',Colours(3,:));
h6=loglog(OmEv,imag(GEv),'h','MarkerEdgeColor',Colours(3,:));
h7=loglog(Om,real(GJ(Om,eta,G_Max,tau_Max)),'k-');
h8=loglog(Om,-imag(GJ(Om,eta,G_Max,tau_Max)),'k--');

OmGuideLin1 = logspace(-1,1);
OmGuideLin2 = logspace(0,2);

loglog(OmGuideLin1,10000*eta*OmGuideLin1,'k--');
loglog(OmGuideLin2,0.1*eta*OmGuideLin2.^2,'k--');


hold off
xlabel('\omega [rad/s]')
ylabel('G'',G'''' [Pa]')
%set(get(get(h1,'Annotation'),'LegendInformation'),'IconDisplayStyle','off');
%set(get(get(h3,'Annotation'),'LegendInformation'),'IconDisplayStyle','off');
%set(get(get(h5,'Annotation'),'LegendInformation'),'IconDisplayStyle','off');
%set(get(get(h7,'Annotation'),'LegendInformation'),'IconDisplayStyle','off');
legend('G''  - KC','G''''  - KC','G'' - Mason','G''''  - Mason','G''  - Evans','G''''  - Evans','G''  - Theory','G''''  - Theory','Location','northwest')


%% Test 3: H2O (with noise)
load('C:\Users\ac2014\Documents\MATLAB\LDdiff_H2O_10runs.mat')

lambda = 633*10^(-9);
theta = 173*2*pi/360;
n = 1.33;
q = 4*pi*n*sin(theta/2)/lambda;
g1 = exp(-q^2*msd/2);
tau = tau(1:floor(length(tau)/10));
tau = tau(tau<1e-2);
g1 = g1(1:length(tau));
tau(1)=[];
msd(1)=[];
g1(1)=[];
LogInt = unique(round(logspace(0,log10(length(g1)),300)))';
msd=msd(LogInt);
tau=tau(LogInt);
g1=g1(LogInt);

% Parameters specification:
Ng = 161;
Nl = 0;
ILT_Input.Iquad = 2;      % Simpson's rule
ILT_Input.Igrid = 2;      % Log grid
ILT_Input.Kernel = 1;     % ILT Kernel
ILT_Input.Nnq = 0;        
ILT_Input.Anq = 0;
ILT_Input.Neq = 0;
ILT_Input.Aeq = 0;
ILT_Input.Nneg = 1;       % Non-negativity constraint
ILT_Input.Ny0 = 1;        % y(0)=1 condition
ILT_Input.iwt = 1;        % Unweighted analysis
ILT_Input.alpha_lims = [0.01,100];
ILT_Input.Nbg = 1;

[s,g,yfit,lambda,info] = CRIE(tau,g1,Ng,Nl,ILT_Input);
loglog(tau,3*msd,tau,-(6/q^2)*log(yfit))
%%
s_Ref = s;  
s_Ref(s_Ref < 1e-6*max(s))=0; %Eliminate numerical noise in s (by clipping to 0)
s_Ref_Ex = s_Ref;
s_Ref_Ex(s_Ref_Ex < max(s_Ref))=0;
dMSD_KC = (6/q^2) * info.A * (s_Ref.*g) ./ (info.A * (s_Ref));
dMSD_KC_Ex = (6/q^2) * info.A * (s_Ref_Ex.*g) ./ (info.A * (s_Ref_Ex));
dMSD_KC = rmmissing(dMSD_KC); %Remove NaNs (due to dividing per zero)
dMSD_KC(dMSD_KC==0)=[]; %Remove zeros (unphysical)
dMSD_KC_Ex = rmmissing(dMSD_KC_Ex); %Remove NaNs (due to dividing per zero)
dMSD_KC_Ex(dMSD_KC_Ex==0)=[]; %Remove zeros (unphysical)

tau_KC = tau(1:length(dMSD_KC));
tau_KC_Ex = tau(1:length(dMSD_KC_Ex));

figure(1)
semilogx(tau,yfit,tau,info.A * abs(s_Ref),'*',tau,info.A * abs(s_Ref_Ex),'o')
figure(2)
yyaxis left
loglog(tau,3*msd,'-',tau,6*D0*tau,'k--')
yyaxis right
loglog(tau_KC,dMSD_KC,tau_KC_Ex,dMSD_KC_Ex,tau(1:end-1),3*diff(msd)./diff(tau))
%%
% Parameters specification:
Ng = 161;
Nl = 1;
ILT_Input.Iquad = 2;      % Simpson's rule
ILT_Input.Igrid = 2;      % Log grid
ILT_Input.Kernel = 1;     % ILT Kernel
ILT_Input.Nnq = 0;        
ILT_Input.Anq = 0;
ILT_Input.Neq = 0;
ILT_Input.Aeq = 0;
ILT_Input.Nneg = 1;       % Non-negativity constraint
ILT_Input.Ny0 = 0;        % y(0)=1 condition
ILT_Input.iwt = 1;        % Unweighted analysis
ILT_Input.alpha_lims = [0.01,100];
ILT_Input.Nbg = 1;

[s,g,yfit,lambda,info] = CRIE(tau_KC,dMSD_KC,Ng,Nl,ILT_Input);
[s_Ex,g_Ex,yfit_Ex,lambda_Ex,info_Ex] = CRIE(tau_KC_Ex,dMSD_KC_Ex,Ng,Nl,ILT_Input);
%%
Om = logspace(log10(1/t(end-3)),log10(1/t(1)),100)';

bg_term = s(end);
fit_term = info.A(:,1:end-Nl)*s(1:end-Nl);
if all(abs(fit_term)./bg_term<1e-3) 
    s(1:end-Nl,:) = 0;
end
s = abs(s);
[gM,~] = meshgrid(info.g,Om);
[cM,OmM] = meshgrid(info.c,Om);
A_s = cM.*(log(10)*10.^(gM)).*1./(OmM.*(10.^gM + OmM));
A_Om = cM.*(log(10)*10.^(gM)).*1./(1i*OmM.*(10.^gM + 1i*OmM));
y_s = A_s*s(1:end-Nl) + s(end)./Om.^2;
y_Om = A_Om*s(1:end-Nl) - s(end)./Om.^2;
y_s_Sum = A_s*s(1:end-Nl);
y_Om_Sum = A_Om*s(1:end-Nl);
y_Om_Const =  - s(end)./Om.^2;
G_s = 3*kB*T./(3*pi*R*Om.*y_s);
G_Om = 3*kB*T./(3*pi*R*1i*Om.*y_Om);
G_p_Om = real(G_Om);
G_pp_Om = imag(G_Om);
% clip off the suspicious (i.e. unreliable) data
for i = 1:length(Om)
    w = find(G_p_Om(i,:) < G_s(i,:)*1e-2);
    G_p_Om(i,w)=0;
    w = find(G_pp_Om(i,:) < G_s(i,:)*1e-2); 
    G_pp_Om(i,w)=0;
end
G_Om_Sum = 3*kB*T./(3*pi*R*1i*Om.*y_Om_Sum);
G_Om_Const = 3*kB*T./(3*pi*R*1i*Om.*y_Om_Const);

bg_term_Ex = s_Ex(end);
fit_term_Ex = info_Ex.A(:,1:end-Nl)*s_Ex(1:end-Nl);

if all(abs(fit_term_Ex)./bg_term_Ex<0)
    s_Ex(1:end-Nl,:) = 0;
end

s_Ex = abs(s_Ex);
[gM_Ex,~] = meshgrid(info_Ex.g,Om);
[cM_Ex,OmM_Ex] = meshgrid(info_Ex.c,Om);
A_Ex = cM_Ex.*(log(10)*10.^(gM_Ex)).*1./(1i*OmM_Ex.*(10.^gM_Ex + 1i*OmM_Ex));
y_Ex = A_Ex*s_Ex(1:end-Nl) - s_Ex(end)./Om.^2;
G_Ex = 3*kB*T./(3*pi*R*1i*Om.*y_Ex);
%%
[OmMas,GMas]=MSDtoG_Mason(tau,3*msd,'R',115e-9,'CG',1.01,'T',T,'cutoff',0);
%%
[OmEv,GEv]=MSDtoG_Evans_oversampling(tau,3*msd,1e6,'R',115e-9,'CG',1.01,'T',T,'Beta',1,'Jfactor',J0);
%%
Colours = get(groot,'DefaultAxesColorOrder');
h1=loglog(Om,G_p_Om,'o','MarkerEdgeColor',Colours(1,:),'MarkerFaceColor',Colours(1,:));
hold on
h2=loglog(Om,G_pp_Om,'o','MarkerEdgeColor',Colours(1,:));
h3=loglog(OmMas,real(GMas),'s','MarkerEdgeColor',Colours(2,:),'MarkerFaceColor',Colours(2,:));
h4=loglog(OmMas,imag(GMas),'s','MarkerEdgeColor',Colours(2,:));
h5=loglog(OmEv,real(GEv),'h','MarkerEdgeColor',Colours(3,:),'MarkerFaceColor',Colours(3,:));
h6=loglog(OmEv,imag(GEv),'h','MarkerEdgeColor',Colours(3,:));
% h9=loglog(Om,real(G_Om_Sum),'o','MarkerEdgeColor',Colours(4,:),'MarkerFaceColor',Colours(4,:));
% h10=loglog(Om,imag(G_Om_Sum),'o','MarkerEdgeColor',Colours(4,:));
% h11=loglog(Om,real(G_Om_Const),'o','MarkerEdgeColor',Colours(5,:),'MarkerFaceColor',Colours(5,:));
% h12=loglog(Om,imag(G_Om_Const),'o','MarkerEdgeColor',Colours(5,:));
h7=loglog(Om,zeros(length(Om),1),'k-');
h8=loglog(Om,eta*Om,'k--');
hold off
xlabel('\omega [rad/s]')
ylabel('G'',G'''' [Pa]')
%set(get(get(h1,'Annotation'),'LegendInformation'),'IconDisplayStyle','off');
%set(get(get(h3,'Annotation'),'LegendInformation'),'IconDisplayStyle','off');
%set(get(get(h5,'Annotation'),'LegendInformation'),'IconDisplayStyle','off');
%set(get(get(h7,'Annotation'),'LegendInformation'),'IconDisplayStyle','off');
legend('G''  - KC','G''''  - KC','G'' - Mason','G''''  - Mason','G''  - Evans','G''''  - Evans','G''  - Theory','G''''  - Theory','Location','northwest')

%% Test 4: H2O (with noise, new method)
load('C:\Users\ac2014\Documents\MATLAB\LDdiff_H2O_10runs.mat')

lambda = 633*10^(-9);
theta = 173*2*pi/360;
n = 1.33;
q = 4*pi*n*sin(theta/2)/lambda;
g1 = exp(-q^2*msd/2);
tau = tau(1:floor(length(tau)/10));
g1 = g1(1:length(tau));
tau(1)=[];
msd(1)=[];
g1(1)=[];
LogInt = unique(round(logspace(0,log10(length(g1)),300)))';
msd=msd(LogInt);
tau=tau(LogInt);
g1=g1(LogInt);

% Parameters specification:
Ng = 161;
Nl = 0;
ILT_Input.Iquad = 2;      % Simpson's rule
ILT_Input.Igrid = 2;      % Log grid
ILT_Input.Kernel = 1;     % ILT Kernel
ILT_Input.Nnq = 0;        
ILT_Input.Anq = 0;
ILT_Input.Neq = 0;
ILT_Input.Aeq = 0;
ILT_Input.Nneg = 1;       % Non-negativity constraint
ILT_Input.Ny0 = 1;        % y(0)=1 condition
ILT_Input.iwt = 1;        % Unweighted analysis
ILT_Input.alpha_lims = [0.01,100];
ILT_Input.Nbg = 1;

[s,g,yfit,lambda,info] = CRIE(tau,g1,Ng,Nl,ILT_Input);
%%
s_Ref = s;  
s_Ref(s_Ref < 1e-6*max(s))=0; %Eliminate numerical noise in s (by clipping to 0)
s_Ref_Ex = s_Ref;
s_Ref_Ex(s_Ref_Ex < max(s_Ref))=0;
dMSD_KC = (6/q^2) * info.A * (s_Ref.*g) ./ (info.A * (s_Ref));
dMSD_KC_Ex = (6/q^2) * info.A * (s_Ref_Ex.*g) ./ (info.A * (s_Ref_Ex));
dMSD_KC = rmmissing(dMSD_KC); %Remove NaNs (due to dividing per zero)
dMSD_KC(dMSD_KC==0)=[]; %Remove zeros (unphysical)
dMSD_KC_Ex = rmmissing(dMSD_KC_Ex); %Remove NaNs (due to dividing per zero)
dMSD_KC_Ex(dMSD_KC_Ex==0)=[]; %Remove zeros (unphysical)

tau_KC = tau(1:length(dMSD_KC)-1);
dMSD_KC(end)=[];
tau_KC_Ex = tau(1:length(dMSD_KC_Ex));

figure(1)
semilogx(tau,yfit,tau,info.A * abs(s_Ref),'*',tau,info.A * abs(s_Ref_Ex),'o')
figure(2)
yyaxis left
loglog(tau,3*msd,'-',tau,6*D0*tau,'k--')
yyaxis right
loglog(tau_KC,dMSD_KC,tau_KC_Ex,dMSD_KC_Ex,tau(1:end-1),3*diff(msd)./diff(tau))
%%
%dMSD_KC = dMSD_KC(1)*ones(length(dMSD_KC),1);
k1 = dMSD_KC(1);
k2 = dMSD_KC(end);
dMSD_pp = csape(tau_KC,dMSD_KC,'variational'); %Natural cubic spline
dMSD_pp_t = dMSD_pp.breaks';
dMSD_pp_A = dMSD_pp.coefs;

semilogx(tau_KC,dMSD_KC,tau_KC,fnval(dMSD_pp,tau_KC),'*')


Om = logspace(log10(1/tau_KC(end-3)),log10(1/tau_KC(1)),100)';


[Lap_Om,Lap_t] = meshgrid(Om,dMSD_pp_t);
% Lap_sum_0 = exp(-Lap_Om.*Lap_t);
Lap_sum_0_R = cos(Lap_Om.*Lap_t);
Lap_sum_0_I = sin(Lap_Om.*Lap_t);
%Lap_sum_1 = exp(-Lap_Om.*Lap_t).*(1./Lap_Om + Lap_t);
Lap_sum_1_R = Lap_t.*cos(Lap_Om.*Lap_t) - (1./Lap_Om).*sin(Lap_Om.*Lap_t);
Lap_sum_1_I = Lap_t.*sin(Lap_Om.*Lap_t) + (1./Lap_Om).*cos(Lap_Om.*Lap_t) ;
%Lap_sum_2 = exp(-Lap_Om.*Lap_t).*(2./Lap_Om.^2 + (2./Lap_Om).*Lap_t + Lap_t.^2);
Lap_sum_2_R = (Lap_t.^2 - 2./Lap_Om.^2).*cos(Lap_Om.*Lap_t) - (2*Lap_t./Lap_Om).*sin(Lap_Om.*Lap_t);
Lap_sum_2_I = (Lap_t.^2 - 2./Lap_Om.^2).*sin(Lap_Om.*Lap_t) + (2*Lap_t./Lap_Om).*cos(Lap_Om.*Lap_t);
%Lap_sum_3 = exp(-Lap_Om.*Lap_t).*(6./Lap_Om.^3 + (6./Lap_Om.^2).*Lap_t +  + (3./Lap_Om).*Lap_t.^2 + Lap_t.^3);
Lap_sum_3_R = (Lap_t.^3 - 6*Lap_t./Lap_Om.^2).*cos(Lap_Om.*Lap_t) - (3*Lap_t.^2 ./ Lap_Om - 6./Lap_Om.^3).*sin(Lap_Om.*Lap_t);
Lap_sum_3_I = (Lap_t.^3 - 6*Lap_t./Lap_Om.^2).*sin(Lap_Om.*Lap_t) + (3*Lap_t.^2 ./ Lap_Om - 6./Lap_Om.^3).*cos(Lap_Om.*Lap_t);
%Lap_sum_tot =  sum(repmat(dMSD_pp_A(:,4),1,length(Om)).*diff(Lap_sum_0) + ...
%                               + repmat(dMSD_pp_A(:,3),1,length(Om)).*diff(Lap_sum_1) + ...
%                               + repmat(dMSD_pp_A(:,2),1,length(Om)).*diff(Lap_sum_2) + ...
%                               + repmat(dMSD_pp_A(:,1),1,length(Om)).*diff(Lap_sum_3) )';
Lap_sum_tot_R = sum(repmat(dMSD_pp_A(:,4),1,length(Om)).*diff(Lap_sum_0_R) + ...
                   + repmat(dMSD_pp_A(:,3),1,length(Om)).*diff(Lap_sum_1_R) + ...
                   + repmat(dMSD_pp_A(:,2),1,length(Om)).*diff(Lap_sum_2_R) + ...
                   + repmat(dMSD_pp_A(:,1),1,length(Om)).*diff(Lap_sum_3_R) )' ;
Lap_sum_tot_R = 1./Om.*(Lap_sum_tot_R + k1*cos(-Om*dMSD_pp_t(1)) - k2*cos(-Om*dMSD_pp_t(end)) - k1);
 
Lap_sum_tot_I = -sum(repmat(dMSD_pp_A(:,4),1,length(Om)).*diff(Lap_sum_0_I) + ...
                   + repmat(dMSD_pp_A(:,3),1,length(Om)).*diff(Lap_sum_1_I) + ...
                   + repmat(dMSD_pp_A(:,2),1,length(Om)).*diff(Lap_sum_2_I) + ...
                   + repmat(dMSD_pp_A(:,1),1,length(Om)).*diff(Lap_sum_3_I) )';
Lap_sum_tot_I = 1./Om.*(Lap_sum_tot_I + k1*sin(-Om*dMSD_pp_t(1)) - k2*sin(-Om*dMSD_pp_t(end)));
              
% Lap_sum_tottot = 1./(1i*Om) .* (-Lap_sum_tot + (k1*(1-exp(-(1i*Om)*dMSD_pp_t(1))) + k2*exp(-(1i*Om)*dMSD_pp_t(end))));
Lap_tot = 1i*(Lap_sum_tot_R + 1i*Lap_sum_tot_I);
G_Om = 3*kB*T./(3*pi*R*Lap_tot);
loglog(Om,real(G_Om),Om,imag(G_Om))

%%
tau_KC_Ov = linspace(tau_KC(1),tau_KC(end),1e6)';
[gM,~] = meshgrid(info.g,tau_KC_Ov);
[cM,tM] = meshgrid(info.c,tau_KC_Ov);
A_Om = cM.*(log(10)*10.^(gM)).*exp(-tM.*10.^(gM));
%%
dMSD_KC_Ov = (6/q^2) * A_Om * (s_Ref.*g) ./ (A_Om * (s_Ref));
k1_Ov = dMSD_KC_Ov(1);
k2_Ov = dMSD_KC_Ov(end);
dMSD_pp_Ov = csape(tau_KC_Ov,dMSD_KC_Ov,'variational'); %Natural cubic spline
dMSD_pp_Ov_t = dMSD_pp_Ov.breaks';
dMSD_pp_Ov_A = dMSD_pp_Ov.coefs;

semilogx(tau_KC,dMSD_KC,tau_KC,fnval(dMSD_pp,tau_KC),'*')


Om = logspace(log10(1/tau_KC(end-3)),log10(1/tau_KC(1)),100)';


[Lap_Om,Lap_t] = meshgrid(Om,dMSD_pp_Ov_t);
% Lap_sum_0 = exp(-Lap_Om.*Lap_t);
Lap_sum_0_R = cos(Lap_Om.*Lap_t);
Lap_sum_0_I = sin(Lap_Om.*Lap_t);
%Lap_sum_1 = exp(-Lap_Om.*Lap_t).*(1./Lap_Om + Lap_t);
Lap_sum_1_R = Lap_t.*cos(Lap_Om.*Lap_t) - (1./Lap_Om).*sin(Lap_Om.*Lap_t);
Lap_sum_1_I = Lap_t.*sin(Lap_Om.*Lap_t) + (1./Lap_Om).*cos(Lap_Om.*Lap_t) ;
%Lap_sum_2 = exp(-Lap_Om.*Lap_t).*(2./Lap_Om.^2 + (2./Lap_Om).*Lap_t + Lap_t.^2);
Lap_sum_2_R = (Lap_t.^2 - 2./Lap_Om.^2).*cos(Lap_Om.*Lap_t) - (2*Lap_t./Lap_Om).*sin(Lap_Om.*Lap_t);
Lap_sum_2_I = (Lap_t.^2 - 2./Lap_Om.^2).*sin(Lap_Om.*Lap_t) + (2*Lap_t./Lap_Om).*cos(Lap_Om.*Lap_t);
%Lap_sum_3 = exp(-Lap_Om.*Lap_t).*(6./Lap_Om.^3 + (6./Lap_Om.^2).*Lap_t +  + (3./Lap_Om).*Lap_t.^2 + Lap_t.^3);
Lap_sum_3_R = (Lap_t.^3 - 6*Lap_t./Lap_Om.^2).*cos(Lap_Om.*Lap_t) - (3*Lap_t.^2 ./ Lap_Om - 6./Lap_Om.^3).*sin(Lap_Om.*Lap_t);
Lap_sum_3_I = (Lap_t.^3 - 6*Lap_t./Lap_Om.^2).*sin(Lap_Om.*Lap_t) + (3*Lap_t.^2 ./ Lap_Om - 6./Lap_Om.^3).*cos(Lap_Om.*Lap_t);
%Lap_sum_tot =  sum(repmat(dMSD_pp_A(:,4),1,length(Om)).*diff(Lap_sum_0) + ...
%                               + repmat(dMSD_pp_A(:,3),1,length(Om)).*diff(Lap_sum_1) + ...
%                               + repmat(dMSD_pp_A(:,2),1,length(Om)).*diff(Lap_sum_2) + ...
%                               + repmat(dMSD_pp_A(:,1),1,length(Om)).*diff(Lap_sum_3) )';
Lap_sum_tot_R = sum(repmat(dMSD_pp_Ov_A(:,4),1,length(Om)).*diff(Lap_sum_0_R) + ...
                   + repmat(dMSD_pp_Ov_A(:,3),1,length(Om)).*diff(Lap_sum_1_R) + ...
                   + repmat(dMSD_pp_Ov_A(:,2),1,length(Om)).*diff(Lap_sum_2_R) + ...
                   + repmat(dMSD_pp_Ov_A(:,1),1,length(Om)).*diff(Lap_sum_3_R) )' ;
Lap_sum_tot_R = 1./Om.*(Lap_sum_tot_R + k1*cos(-Om*dMSD_pp_Ov_t(1)) - k2*cos(-Om*dMSD_pp_Ov_t(end)) - k1);
 
Lap_sum_tot_I = -sum(repmat(dMSD_pp_Ov_A(:,4),1,length(Om)).*diff(Lap_sum_0_I) + ...
                   + repmat(dMSD_pp_Ov_A(:,3),1,length(Om)).*diff(Lap_sum_1_I) + ...
                   + repmat(dMSD_pp_Ov_A(:,2),1,length(Om)).*diff(Lap_sum_2_I) + ...
                   + repmat(dMSD_pp_Ov_A(:,1),1,length(Om)).*diff(Lap_sum_3_I) )';
Lap_sum_tot_I = 1./Om.*(Lap_sum_tot_I + k1*sin(-Om*dMSD_pp_Ov_t(1)) - k2*sin(-Om*dMSD_pp_Ov_t(end)));
              
% Lap_sum_tottot = 1./(1i*Om) .* (-Lap_sum_tot + (k1*(1-exp(-(1i*Om)*dMSD_pp_t(1))) + k2*exp(-(1i*Om)*dMSD_pp_t(end))));
Lap_tot = 1i*(Lap_sum_tot_R + 1i*Lap_sum_tot_I);
G_Om = 3*kB*T./(3*pi*R*Lap_tot);
loglog(Om,real(G_Om),Om,imag(G_Om))
