classdef InducedDipole < EField
    % InducedDipole < EField : Induced dipole
    %
    % InducedDipole properties:
    %   lambda0 -   vacuum wavelength [m] < EField
    %   er      -   relative dielectric permittivity < EField
    %   mr      -   relative magnetic permeability < EField
    %   alpha   -   polarizability [Cm^2/V]
    %   rd      -   position (Point) [m]
    %
    % InducedDipole methods:
    %   InducedDipole   -   constructor 
    %   n               -   refractive index < EField
    %   lambda          -   wavelenght in the medium [m]  < EField
    %   k               -   wave number in the medium [m^-1]  < EField
    %   omega           -   angular frequency [Hz]  < EField
    %   B               -   magnetic field [T] < EField
    %   S               -   Poynting vector (Vector) [W/m^2] < EField
    %   Ls            	-   spin density [kg m^2/s] < EField
    %   E               -   electric field [V/m]
    %   dipolemoment    -   dipole moment
    %   Estandard       -   electric field for a dipole with p = 1 at the origin and orineted along z [V/m]
    %   sext            -   extinction cross-section [m^-2]
    %   sscat           -   scattering cross-section [m^-2]
    %   sabs            -   absorption cross-section [m^-2]
    %   force           -   force on the dipole in a EM field [N]
    %   force_general   -   force on the dipole in a general EM field [N]
    %
    % InducedDipole static method:
    %   polarizability  -   polarizability
    %
    % See also EField.

    %   Author: Giovanni Volpe
    %   Revision: 1.0.0  
    %   Date: 2015/01/01

    properties
        alpha   % polarizability [Cm^2/V]
        rd      % position (Point) [m]
    end
    methods
        function id = InducedDipole(alpha,varargin)
            % INDUCEDDIPOLE(ALPHA) constructs an induced dipole of polarizability ALPHA.
            %
            % EFIELDFOCUS(ALPHA,'PropertyName',PropertyValue) sets the property
            %   PropertyName to PropertyValue. The properties listed below
            %   can be used:
            %       lambda0     -   vacuum wavelength [default: 532e-9 m]
            %       er          -   relative electric permittivity [default: 1]
            %       mr          -   relative magnetic permeability [default: 1]
            %       rd          -	Position (Point) [default: Point(0,0,0)]
            %
            % See also InducedDipole, EField.

            id = id@EField(varargin{:});            

            Check.isnumeric('The polarizability must be a number',alpha)

            id.alpha = alpha;

            % Position
            id.rd = Point(0,0,0);
            for n = 1:2:length(varargin)
                if strcmpi(varargin{n},'rd')
                    id.rd = varargin{n+1};
                    Check.isa('The position of a dipole must be a Point',id.rd,'Point')
                end
            end
            
        end
        function E = E(id,R,Ei)
            % E Electric field [V/m]
            %
            % E = E(ID,R,Ei) calculates the electric field at positions R (Point)
            %   for the induced dipole ID usbject to the electric field Ei.
            %   E is a ComplexVector.
            %
            % See also InducedDipole, InducedDipole.Estandard, Point, ComplexVector.
                        
            Check.isa('The set of positions where to calculate the electric field must be a Point',R,'Point')
            Check.isa('The inducing electric field must be a ComplexVector',Ei,'ComplexVector')

            p = id.dipolemoment(Ei);

            R = R-id.rd;
            E = p.Vx * id.Estandard(R.yrotation(-pi/2)).yrotation(pi/2) ...
                + p.Vy * id.Estandard(R.xrotation(pi/2)).xrotation(-pi/2) ...
                + p.Vz * id.Estandard(R);
            E.X = E.X+id.rd.X;
            E.Y = E.Y+id.rd.Y;
            E.Z = E.Z+id.rd.Z;
        end
        function p = dipolemoment(id,Ei)
            % DIPOLEMOMENT Electric field
            %
            % P = DIPOLEMOMENT(ID,Ei) calculates the dipole moment of the
            %   induced dipole ID usbject to the electric field Ei.
            %   P is a ComplexVector.
            %
            % See also InducedDipole, ComplexVector.

            Check.isa('The inducing electric field must be a ComplexVector',Ei,'ComplexVector')

            p = id.alpha*Ei;
        end
        function E = Estandard(id,R)
            % ESTANDARD Electric field for a dipole with p = 1 at the origin and orineted along z [V/m]
            %
            % E = ESTANDARD(ID,R) calculates the electric field at positions R (Point)
            %   for the induced dipole with p = 1 at the origin and orineted along z.
            %   E is a ComplexVector.
            %
            % See also InducedDipole, Point, ComplexVector.
            
            ONES = ones(size(R));
            ZEROS = zeros(size(R));

            [theta,phi,r] = Transform.Car2Sph(R.X,R.Y,R.Z);
            kr = id.k()*r;
            
            [Vx,Vy,Vz] = Transform.Sph2CarVector(theta,phi,ZEROS,ZEROS,ONES);
            ur = ComplexVector(R.X,R.Y,R.Z,Vx,Vy,Vz);

            [Vx,Vy,Vz] = Transform.Sph2CarVector(theta,phi,ONES,ZEROS,ZEROS);
            utheta = ComplexVector(R.X,R.Y,R.Z,Vx,Vy,Vz);
            
            E = id.k()^3/(4*pi*PhysConst.e0*id.er) * exp(1i*kr)./kr ...
                .* ( ...
                2*cos(theta).*(kr.^-2-1i*kr.^-1) * ur ...
                + sin(theta).*(kr.^-2-1i*kr.^-1-1) * utheta ...
                );
        end
        function s = sext(id)
            % SEXT Extinction cross-section [m^-2]
            %
            % S = SEXT(ID) calculates the extinction cross-section of ID.
            %
            % See also InducedDipole.

            s = id.k()/(PhysConst.e0*id.er)*imag(id.alpha);
        end
        function s = sscat(id)
            % SSCAT Scattering cross-section [m^-2]
            %
            % S = SSCAT(ID) calculates the extinction cross-section of ID.
            %
            % See also InducedDipole.

            s = id.k()^4/(6*pi*(PhysConst.e0*id.er)^2)*abs(id.alpha)^2;
        end        
        function s = sabs(id)
            % SABS Absorption cross-section [m^-2]
            %
            % S = SABS(ID) calculates the absorption cross-section of ID.
            %
            % See also InducedDipole.

            s = id.sext()-id.sscat();
        end
        function [F,Fgrad,Fscat,Fsc] = force(id,r,ef,varargin)
            % FORCE Force on the dipole in a EM field [N]
            %
            % [F,Fgrad,Fscat,Fsc] = FORCE(ID,R,EF) calculates the force exerted 
            %   on ID by the electric field EF (EField) at positions R (Point).
            %
            % [F,Fgrad,Fscat,Fsc] = FORCE(ID,R,EF,'dr',DR) sets the increment 
            %   in the calcualtion of the derivatives to DR [default = 1e-10 m].
            %
            % See also InducedDipole, EField, Point, Vector.
            
            % increment [m]
            dr = 1e-10;
            for n = 1:2:length(varargin)
                if strcmpi(varargin{n},'dr')
                    dr = varargin{n+1};
                    Check.isnumeric('dr must be a positive real number',dr,'>',0)
                end
            end
                        
            Fgrad = .25*real(id.alpha)*Vector(r.X,r.Y,r.Z, ...
                ( norm(ef.E(r+Point(dr,0,0))).^2 - norm(ef.E(r+Point(-dr,0,0))).^2 )/(2*dr), ...
                ( norm(ef.E(r+Point(0,dr,0))).^2 - norm(ef.E(r+Point(0,-dr,0))).^2 )/(2*dr), ...
                ( norm(ef.E(r+Point(0,0,dr))).^2 - norm(ef.E(r+Point(0,0,-dr))).^2 )/(2*dr) ...
                );
            
            Fscat = id.sext()*id.n()/PhysConst.c0*ef.S(r,varargin{:});
            
            [Ls,DxLs] = ef.Ls(r,varargin{:});
            
            Fsc = real(id.sext()*PhysConst.c0/id.n()*DxLs);
            
            F = Fgrad + Fscat + Fsc;
            
        end
        function [F,Fgrad,Fscat] = force_general(id,R,E,B,dim,varargin)
            % FORCE_GENERAL Force on the dipole in a general EM field [N]
            %
            % [F,Fgrad,Fscat] = FORCE_GENERAL(ID,R,E,B,dim) calculates the force exerted 
            %   on ID by the electric field E (ComplexVector) at positions
            %   R (Point). The input field is of dimension dim. If 2D, it
            %   assumes a XY slice. If 1D, it assumes a X slice.
            %
            % [F,Fgrad,Fscat] = FORCE_GENERAL(ID,R,E,B,dim,'dr',DR) sets the increment 
            %   in the calcualtion of the derivatives to DR [default = 1e-12 m].
            %
            % See also InducedDipole, Point, Vector.
            
            dim_dom=size(R);
            dim_El=size(E);
            
            if(length(dim_dom)<=2)
                if (~any(dim_El - [1 1]))
                    %0D matrix, throw error!
                    error('The E matrix cannot be 0-dimensional')
                end
            end
            if(any([max(max((R.X))),max(max((R.Y))),max(max((R.Z)))]>[max(max((E.X))) max(max((E.Y))) max(max((E.Z)))]))
                error('R is out of bound.')
            end
            if(any([min(min((R.X))),min(min((R.Y))),min(min((R.Z)))]<[min(min((E.X))) min(min((E.Y))) min(min((E.Z)))]))
                error('R is out of bound.')
            end
            
            if(length(dim_dom)>length(dim_El))
                error('Dimension mismatch between R and El')
            end
            
            S = .5/(PhysConst.m0*id.mr)*real(E*conj(B));
            switch dim
                case 3
                    E.Vx((E.X==0)&(E.Y==0)&(E.Z==0))=max(max(max(real(E.Vx))));
                    E.Vy((E.X==0)&(E.Y==0)&(E.Z==0))=max(max(max(real(E.Vy))));
                    E.Vz((E.X==0)&(E.Y==0)&(E.Z==0))=max(max(max(real(E.Vz))));
                    
                    P = [2 1 3];
                    %temp matrices
                    X=permute(E.X,P);
                    Y=permute(E.Y,P);
                    Z=permute(E.Z,P);
                    Exinterp=griddedInterpolant(X,Y,Z,permute(E.Vx,P),'spline');
                    Eyinterp=griddedInterpolant(X,Y,Z,permute(E.Vy,P),'spline');
                    Ezinterp=griddedInterpolant(X,Y,Z,permute(E.Vz,P),'spline');
                    
                    % increment [m]
                    dr = 1e-12;
                    for n = 1:2:length(varargin)
                        if strcmpi(varargin{n},'dr')
                            dr = varargin{n+1};
                            Check.isnumeric('dr must be a positive real number',dr,'>',0)
                        end
                    end
                    %temp matrices
                    X=permute(R.X,P);
                    Y=permute(R.Y,P);
                    Z=permute(R.Z,P);
                    Fgrad = .25*real(id.alpha)*Vector(R.X,R.Y,R.Z, ...
                        (...
                        norm(ComplexVector(R.X+dr,R.Y,R.Z,permute(Exinterp(X+dr,Y,Z),P),permute(Eyinterp(X+dr,Y,Z),P),permute(Ezinterp(X+dr,Y,Z),P))).^2 ...
                        - norm(ComplexVector(R.X-dr,R.Y,R.Z,permute(Exinterp(X-dr,Y,Z),P),permute(Eyinterp(X-dr,Y,Z),P),permute(Ezinterp(X-dr,Y,Z),P))).^2 ...
                        )/(2*dr), ...
                        (...
                        norm(ComplexVector(R.X,R.Y+dr,R.Z,permute(Exinterp(X,Y+dr,Z),P),permute(Eyinterp(X,Y+dr,Z),P),permute(Ezinterp(X,Y+dr,Z),P))).^2 ...
                        - norm(ComplexVector(R.X,R.Y-dr,R.Z,permute(Exinterp(X,Y-dr,Z),P),permute(Eyinterp(X,Y-dr,Z),P),permute(Ezinterp(X,Y-dr,Z),P))).^2 ...
                        )/(2*dr),...
                        (...
                        norm(ComplexVector(R.X,R.Y,R.Z+dr,permute(Exinterp(X,Y,Z+dr),P),permute(Eyinterp(X,Y,Z+dr),P),permute(Ezinterp(X,Y,Z+dr),P))).^2 ...
                        - norm(ComplexVector(R.X,R.Y,R.Z-dr,permute(Exinterp(X,Y,Z-dr),P),permute(Eyinterp(X,Y,Z-dr),P),permute(Ezinterp(X,Y,Z-dr),P))).^2 ...
                        )/(2*dr)...
                        );
                    
                    %temp matrices
                    X=permute(S.X,P);
                    Y=permute(S.Y,P);
                    Z=permute(S.Z,P);
                    Sxinterp=griddedInterpolant(X,Y,Z,permute(S.Vx,P));
                    Syinterp=griddedInterpolant(X,Y,Z,permute(S.Vy,P));
                    Szinterp=griddedInterpolant(X,Y,Z,permute(S.Vz,P));
                    
                    %temp matrices
                    X=permute(R.X,P);
                    Y=permute(R.Y,P);
                    Z=permute(R.Z,P);
                    Fscat = id.sext()*id.n()/PhysConst.c0*Vector(R.X,R.Y,R.Z,permute(Sxinterp(X,Y,Z),P),permute(Syinterp(X,Y,Z),P),permute(Szinterp(X,Y,Z),P));
                    
                    F = Fgrad + Fscat;
                    
                case 2
                    E.Vx((E.X==0)&(E.Y==0))=max(max(real(E.Vx)));
                    E.Vy((E.X==0)&(E.Y==0))=max(max(real(E.Vy)));
                    E.Vz((E.X==0)&(E.Y==0))=max(max(real(E.Vz)));
                    
                    Exinterp=griddedInterpolant(E.X',E.Y',E.Vx');
                    Eyinterp=griddedInterpolant(E.X',E.Y',E.Vy');
                    Ezinterp=griddedInterpolant(E.X',E.Y',E.Vz');
                    
                    % increment [m]
                    dr = 1e-12;
                    for n = 1:2:length(varargin)
                        if strcmpi(varargin{n},'dr')
                            dr = varargin{n+1};
                            Check.isnumeric('dr must be a positive real number',dr,'>',0)
                        end
                    end
                    
                    Fgrad = .25*real(id.alpha)*Vector(R.X,R.Y,R.Z, ...
                        ( norm(ComplexVector(R.X+dr,R.Y,R.Z,Exinterp(R.X'+dr,R.Y')',Eyinterp(R.X'+dr,R.Y')',Ezinterp(R.X'+dr,R.Y')')).^2 - norm(ComplexVector(R.X-dr,R.Y,R.Z,Exinterp(R.X'-dr,R.Y')',Eyinterp(R.X'-dr,R.Y')',Ezinterp(R.X'-dr,R.Y')')).^2 )/(2*dr), ...
                        ( norm(ComplexVector(R.X,R.Y+dr,R.Z,Exinterp(R.X',R.Y'+dr)',Eyinterp(R.X',R.Y'+dr)',Ezinterp(R.X',R.Y'+dr)')).^2 - norm(ComplexVector(R.X,R.Y-dr,R.Z,Exinterp(R.X',R.Y'-dr)',Eyinterp(R.X',R.Y'-dr)',Ezinterp(R.X',R.Y'-dr)')).^2 )/(2*dr), ...
                        ( zeros(size(R)) ) ...
                        );
                                        
                    Sxinterp=griddedInterpolant(S.X',S.Y',S.Vx');
                    Syinterp=griddedInterpolant(S.X',S.Y',S.Vy');
                    
                    Fscat = id.sext()*id.n()/PhysConst.c0*Vector(R.X,R.Y,R.Z,Sxinterp(R.X',R.Y')',Syinterp(R.X',R.Y')',0);
                    
                    F = Fgrad + Fscat;
                    
                case 1
                    E.Vx((E.X==0))=max(real(E.Vx));
                    E.Vy((E.X==0))=max(real(E.Vy));
                    E.Vz((E.X==0))=max(real(E.Vz));
                    
                    Exinterp=griddedInterpolant(E.X',E.Vx');
                    Eyinterp=griddedInterpolant(E.X',E.Vy');
                    Ezinterp=griddedInterpolant(E.X',E.Vz');
                    
                    % increment [m]
                    dr = 1e-12;
                    for n = 1:2:length(varargin)
                        if strcmpi(varargin{n},'dr')
                            dr = varargin{n+1};
                            Check.isnumeric('dr must be a positive real number',dr,'>',0)
                        end
                    end
                    
                    Fgrad = .25*real(id.alpha)*Vector(R.X,R.Y,R.Z, ...
                        ( norm(ComplexVector(R.X+dr,R.Y,R.Z,Exinterp(R.X'+dr)',Eyinterp(R.X'+dr)',Ezinterp(R.X'+dr)')).^2 - norm(ComplexVector(R.X-dr,R.Y,R.Z,Exinterp(R.X'-dr)',Eyinterp(R.X'-dr)',Ezinterp(R.X'-dr)')).^2 )/(2*dr), ...
                        ( zeros(size(R)) ), ...
                        ( zeros(size(R)) ) ...
                        );
                                        
                    Sxinterp=griddedInterpolant(S.X',S.Vx');
                    
                    Fscat = id.sext()*id.n()/PhysConst.c0*Vector(R.X,R.Y,R.Z,Sxinterp(R.X')',zeros(size(R)),zeros(size(R)));
                    
                    F = Fgrad + Fscat;
            end
            
            
        end
    end
    methods (Static)
        function alpha = polarizability(kind,a,ep,varargin)
            % POLARIZABILITY Polarizability
            %
            % ALPHA = POLARIZABILITY(KIND,A,EP) calcualtes the
            %   polarizability of spherical particle of radius A and
            %   relative refractive index EP.
            %   KIND = 'Corrected' uses the formula with radiative correction
            %   KIND = 'Clausius-Mossotti' uses the Clausius-Mossotti formula, 
            %
            % ALPHA = POLARIZABILITY(KIND,A,EP,'PropertyName',PropertyValue) sets the property
            %   PropertyName to PropertyValue. The properties listed below
            %   can be used:
            %       lambda0     -   vacuum wavelength [default: 532e-9 m]
            %       em          -   relative electric permittivity [default: 1]
            %   
            % See also InducedDipole
            
            Check.isreal('The radius must be a positive real number',a,'>',0)
            Check.isnumeric('The particle polarisability must be a real number',ep)

            % medium relative dielectric constant
            em = 1;
            for n = 1:2:length(varargin)
                if strcmpi(varargin{n},'em')
                    em = varargin{n+1};
                    Check.isreal('em must be a real number greater than or equal to 1',em,'>=',1)
                end
            end
            
            er = ep/em;
            
            switch lower(kind)
                
                case 'clausius-mossotti'
                    V = 4/3*pi*a.^3;
                    alpha = 3*V*PhysConst.e0*em * (er-1)/(er+2);
                    
                otherwise % polarizability with radiative correction

                    % vacuum wavelength [m]
                    lambda0 = 532e-9;
                    for n = 1:2:length(varargin)
                        if strcmpi(varargin{n},'lambda0')
                            lambda0 = varargin{n+1};
                            Check.isreal('lambda0 must be a positive real number',lambda0,'>',0)
                        end
                    end
                    
                    lambda = lambda0/sqrt(em);
                    ka = 2*pi/lambda*a;
            
                    alpha0 = InducedDipole.polarizability('Clausius-Mossotti',a,ep,varargin{:});
                    alpha = alpha0.*(1-(er-1)/(er+2)*( ka.^2 + 2*1i/3*ka.^3) ).^-1;
                    
            end
        end
    end
end