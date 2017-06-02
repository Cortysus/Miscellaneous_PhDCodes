%% INITIALIZATION
ep = 2.25;
a = .2e-6;
lambda0 = 1064e-9;
alpharc = InducedDipole.polarizability('corrected',a,ep,'lambda0',lambda0);
Iel=1e12;
El=sqrt(Iel/(PhysConst.c0*PhysConst.e0));
Ei = ComplexVector(0,0,0,El/2,0,0);
E_inc = EFieldPlaneWave(El/2,Vector(0,0,0,0,0,1),Vector(0,0,0,1,0,0));



%% 2 INTERACTING DIPOLES: ITERATIVE SOLVER

%Fixed position
x1=0;
y1=0;
z1=0;
r1=Point(x1,y1,z1);

% Variable position: Coarse mesh
[x,y,z] = meshgrid(-2e-6:.5e-7:2e-6,-2e-6:.5e-7:2e-6,0);
r = Point(x,y,z);

Ex=zeros(size(r,1),size(r,2));
Ey=zeros(size(r,1),size(r,2));
Ez=zeros(size(r,1),size(r,2));
Bx=zeros(size(r,1),size(r,2));
By=zeros(size(r,1),size(r,2));
Bz=zeros(size(r,1),size(r,2));
Fx=zeros(size(r,1),size(r,2));
Fy=zeros(size(r,1),size(r,2));
Fz=zeros(size(r,1),size(r,2));
rx=r.X(:);
ry=r.Y(:);
rz=r.Z(:);

%%
% %Enable progress bar for parallel pool
try
    parpool;
catch ME
    if ~strcmp(ME.identifier,'parallel:convenience:ConnectionOpen')
        rethrow(ME)
    end
end
targetWorkCount = size(r,1)*size(r,2);
barWidth= int32( 30 );
p =  TimedProgressBar( targetWorkCount, barWidth, ...
    'Computing, wait for ', ', completed ', 'Concluded in ' );

parfor k = 1:targetWorkCount
    r2=Point(rx(k),ry(k),rz(k));
    rP = [r1,r2];
    idP = InducedDipole(alpharc,'lambda0',lambda0,'rd',rP(1));
    
    for i=2:length(rP)
        idP = [idP,InducedDipole(alpharc,'lambda0',lambda0,'rd',rP(i))];
    end
    
    numDip=2;
    
    if norm(Point(rx(k),ry(k),rz(k)) - r1)<(2*a - 0.5e-7) %For force calculation
        Ex(k)=NaN;
        Ey(k)=NaN;
        Ez(k)=NaN;
        Bx(k)=NaN;
        By(k)=NaN;
        Bz(k)=NaN;
        Fx(k)=NaN;
        Fy(k)=NaN;
        Fz(k)=NaN;
    else
        tol = 1;
        cc = 0;
        Ei_n=[E_inc.E(rP(1)),E_inc.E(rP(2))];
        chk = zeros(1,numDip);
        
        while tol > 0.001 
            Ei_o = Ei_n;
            cc = cc + 1;
            
            Ei_n=[E_inc.E(rP(1)),E_inc.E(rP(2))];
            Bi_n=[E_inc.B(rP(1)),E_inc.B(rP(2))];
            for i=1:length(rP)
                for j=1:length(rP)
                    if i~=j
                        Ei_n(i) = Ei_n(i)+idP(j).E(rP(i),Ei_o(j));
                        Bi_n(i) = Bi_n(i)+idP(j).B(rP(i),Ei_o(j));
                    end
                end
            end
            
            for i=1:length(rP)
                chk(i) = norm(Ei_n(i) - Ei_o(i))./norm(Ei_o(i));
            end
            
            tol = max([real(chk),imag(chk)]);
        end
        
        %Field calculation
        Ex(k)=E_inc.E(r2).Vx + idP(1).E(r2,Ei_n(1)).Vx;
        Ey(k)=E_inc.E(r2).Vy + idP(1).E(r2,Ei_n(1)).Vy;
        Ez(k)=E_inc.E(r2).Vz + idP(1).E(r2,Ei_n(1)).Vz;
        Bx(k)=E_inc.B(r2).Vx + idP(1).B(r2,Ei_n(1)).Vx;
        By(k)=E_inc.B(r2).Vy + idP(1).B(r2,Ei_n(1)).Vy;
        Bz(k)=E_inc.B(r2).Vz + idP(1).B(r2,Ei_n(1)).Vz;
        
        %Force calculation, 5 pts interpol.
        [x_temp,y_temp,z_temp] = meshgrid(r2.X-1e-7:.5e-8:r2.X+1e-7,r2.Y-1e-7:.5e-8:r2.Y+1e-7,0);
        r_temp = Point(x_temp,y_temp,z_temp);


        E_temp = E_inc.E(r_temp) + idP(1).E(r_temp,Ei_n(1));
        B_temp = E_inc.B(r_temp) + idP(1).B(r_temp,Ei_n(1));
        [F_temp,~,~] = idP(2).force_general(r2,E_temp,B_temp,2);
        
        Fx(k)=F_temp.Vx;
        Fy(k)=F_temp.Vy;
        Fz(k)=F_temp.Vz;
        
        if norm(Point(rx(k),ry(k),rz(k)) - r1)<2*a %True cut
            Ex(k)=NaN;
            Ey(k)=NaN;
            Ez(k)=NaN;
            Bx(k)=NaN;
            By(k)=NaN;
            Bz(k)=NaN;
            Fx(k)=NaN;
            Fy(k)=NaN;
            Fz(k)=NaN;
        end
        
    end
    p.progress;

end
p.stop;

Et = ComplexVector(r.X,r.Y,r.Z,Ex,Ey,Ez);
Bt = ComplexVector(r.X,r.Y,r.Z,Bx,By,Bz);
F = ComplexVector(r.X,r.Y,r.Z,Fx,Fy,Fz);
%%
figure(1)
subplot(1,3,1)
surf(r.X,r.Y,norm(Et))
subplot(1,3,2)
surf(norm(Bt))
subplot(1,3,3)
surf(norm(F))
%%

spl=csapi({-2e-6:.5e-7:2e-6,-2e-6:.5e-7:2e-6},Z');
fun = @(X) 1e12*fnval(spl,X');
options=optimset('PlotFcns',@optimplotfval);
minPt=[fminsearch(fun,[1e-20,1.1e-6],options);fminsearch(fun,[1e-20,-1.1e-6],options)];

