classdef EFieldGeneral < EField
    % EFieldGeneral < EField : Electromagnetic field of a general EM wave
    %
    % EFieldGeneral properties:
    %   lambda0 -   vacuum wavelength [m] < EField
    %   er      -   relative dielectric permittivity < EField
    %   mr      -   relative magnetic permeability < EField
    %   Emesh       -   Electric field (ComplexVector) [V/m]
    %   Bmesh       -   magnetic field (ComplexVector) [T]
    %   dim         -   dimension of the field (1,2 or 3D)
    %   Exinterp
    %
    % EFieldGeneral methods:
    %   EFieldGeneral     -   constructor 
    %   n                   -   refractive index < EField
    %   lambda              -   wavelenght in the medium [m]  < EField
    %   k                   -   wave number in the medium [m^-1]  < EField
    %   omega               -   angular frequency [Hz]  < EField
    %   S                   -   Poynting vector (Vector) [W/m^2] < EField
    %   Ls                  -   spin density [kg m^2/s] < EField
    %   E                   -   electric field [V/m]
    %   B                   -   magnetic field [T] 


    %
    % See also EField.

    %   Author: Alessio Caciagli
    %   Revision: 1.0.1  
    %   Date: 2017/01/27
    
    properties
        Emesh   % Electric field (ComplexVector) [V/m]
        Bmesh   % Magnetic field (ComplexVector) [T]
        dim     % Dimension of the field (number)
        Exinterp
        Eyinterp
        Ezinterp
        Bxinterp
        Byinterp
        Bzinterp
    end
    methods
        function ef = EFieldGeneral(E,B,dim,varargin)
            % EFIELDGENERAL(E,B,dim) constructs a EM wave of dimension dim from
            %   its Emesh and Bmeshfields over a domain dom.
            %   The input field is of dimension dim. If 2D, it
            %   assumes a XY slice. If 1D, it assumes a X slice.
            % EFIELDGENERAL(E,B,dim,'PropertyName',PropertyValue) sets the property
            %   PropertyName to PropertyValue. The properties listed below
            %   can be used:
            %       lambda0     -   vacuum wavelength [default: 532e-9 m]
            %       er          -   relative electric permittivity [default: 1]
            %       mr          -   relative magnetic permeability [default: 1]
            %
            %
            % See also EField.
            
            %Consistency checks
            Check.isa('The electric field must be a ComplexVector',E,'ComplexVector')
            Check.isa('The magnetic field must be a ComplexVector',B,'ComplexVector')
            Check.samesize('The electric field, magnetic field and spatial domain must be of the same dimension',E,B)
            Check.samemesh('The electric field and magnetic field must be on same mesh',E,B)
            Check.samedim('Dimension mismatch between the quantities.',dim,E)
            
            ef = ef@EField();
            
            ef.Emesh = E;
            ef.Bmesh = B;
            ef.dim = dim;
            ef.Emesh.Vx=inpaint_nans(ef.Emesh.Vx);
            ef.Emesh.Vy=inpaint_nans(ef.Emesh.Vy);
            ef.Emesh.Vz=inpaint_nans(ef.Emesh.Vz);
            ef.Bmesh.Vx=inpaint_nans(ef.Bmesh.Vx);
            ef.Bmesh.Vy=inpaint_nans(ef.Bmesh.Vy);
            ef.Bmesh.Vz=inpaint_nans(ef.Bmesh.Vz);
            
            switch ef.dim
                case 3
                    P = [2 1 3];
                    %temp matrices
                    X=permute(ef.Emesh.X,P);
                    Y=permute(ef.Emesh.Y,P);
                    Z=permute(ef.Emesh.Z,P);
                    ef.Exinterp=griddedInterpolant(X,Y,Z,permute(ef.Emesh.Vx,P),'spline');
                    ef.Eyinterp=griddedInterpolant(X,Y,Z,permute(ef.Emesh.Vy,P),'spline');
                    ef.Ezinterp=griddedInterpolant(X,Y,Z,permute(ef.Emesh.Vz,P),'spline');
                    ef.Bxinterp=griddedInterpolant(X,Y,Z,permute(ef.Bmesh.Vx,P),'spline');
                    ef.Byinterp=griddedInterpolant(X,Y,Z,permute(ef.Bmesh.Vy,P),'spline');
                    ef.Bzinterp=griddedInterpolant(X,Y,Z,permute(ef.Bmesh.Vz,P),'spline');
                    clear X Y Z
                case 2
                    ef.Exinterp=griddedInterpolant(ef.Emesh.X',ef.Emesh.Y',ef.Emesh.Vx');
                    ef.Eyinterp=griddedInterpolant(ef.Emesh.X',ef.Emesh.Y',ef.Emesh.Vy');
                    ef.Ezinterp=griddedInterpolant(ef.Emesh.X',ef.Emesh.Y',ef.Emesh.Vz');
                    ef.Bxinterp=griddedInterpolant(ef.Bmesh.X',ef.Bmesh.Y',ef.Bmesh.Vx');
                    ef.Byinterp=griddedInterpolant(ef.Bmesh.X',ef.Bmesh.Y',ef.Bmesh.Vy');
                    ef.Bzinterp=griddedInterpolant(ef.Bmesh.X',ef.Bmesh.Y',ef.Bmesh.Vz');
                case 1
                    ef.Exinterp=griddedInterpolant(ef.Emesh.X',ef.Emesh.Vx');
                    ef.Eyinterp=griddedInterpolant(ef.Emesh.X',ef.Emesh.Vy');
                    ef.Ezinterp=griddedInterpolant(ef.Emesh.X',ef.Emesh.Vz');
                    ef.Bxinterp=griddedInterpolant(ef.Bmesh.X',ef.Bmesh.Vx');
                    ef.Byinterp=griddedInterpolant(ef.Bmesh.X',ef.Bmesh.Vy');
                    ef.Bzinterp=griddedInterpolant(ef.Bmesh.X',ef.Bmesh.Vz');
            end
        end
        function E = E(ef,r,varargin)
            % E Electric field [V/m]
            %
            % E = E(EF,R) calculates the electric field at positions R (Point).
            %   E is a ComplexVector.
            %
            % See also EFieldFocus, Beam.focus, Point, ComplexVector.
            
            Check.isa('The set of positions where to calculate the electric field must be a Point',r,'Point')
            Check.outofbound('The Point is out of bound respect to the mesh.',r,ef.Emesh)

            
             switch ef.dim
                case 3
                    P = [2 1 3];
                    %temp matrices            
                    X=permute(R.X,P);
                    Y=permute(R.Y,P);
                    Z=permute(R.Z,P);
                    EX=permute(ef.Exinterp(X,Y,Z),P);
                    EY=permute(ef.Eyinterp(X,Y,Z),P);
                    EZ=permute(ef.Ezinterp(X,Y,Z),P);
                    clear X Y Z
                case 2
                    EX=ef.Exinterp(r.X',r.Y')';
                    EY=ef.Eyinterp(r.X',r.Y')';
                    EZ=ef.Ezinterp(r.X',r.Y')';
                    
                case 1
                    EX=ef.Exinterp(r.X')';
                    EY=ef.Eyinterp(r.X')';
                    EZ=ef.Ezinterp(r.X')';
             end
            
             E=ComplexVector(r.X,r.Y,r.Z,EX,EY,EZ);
        end
        function B = B(ef,r,varargin)
            % B Magnetic field [T]
            %
            % B = B(EF,R) calculates the electric field at positions R (Point).
            %   B is a ComplexVector.
            %
            % See also EFieldFocus, Beam.focus, Point, ComplexVector.
            
            Check.isa('The set of positions where to calculate the magnetic field must be a Point',r,'Point')
            Check.outofbound('The Point is out of bound respect to the mesh.',r,ef.Bmesh)

            
            switch ef.dim
                case 3
                    P = [2 1 3];
                    %temp matrices
                    X=permute(R.X,P);
                    Y=permute(R.Y,P);
                    Z=permute(R.Z,P);
                    BX=permute(ef.Bxinterp(X,Y,Z),P);
                    BY=permute(ef.Byinterp(X,Y,Z),P);
                    BZ=permute(ef.Bzinterp(X,Y,Z),P);
                    clear X Y Z
                case 2
                    BX=ef.Bxinterp(r.X',r.Y')';
                    BY=ef.Byinterp(r.X',r.Y')';
                    BZ=ef.Bzinterp(r.X',r.Y')';
                    
                case 1
                    BX=ef.Bxinterp(r.X')';
                    BY=ef.Byinterp(r.X')';
                    BZ=ef.Bzinterp(r.X')';
            end
            
            B=ComplexVector(r.X,r.Y,r.Z,BX,BY,BZ);
        end       
    end
end