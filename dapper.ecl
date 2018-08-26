EXPORT Dapper := MODULE
    IMPORT std;

    EXPORT Bundle := MODULE(Std.BundleBase)
      EXPORT Name := 'dapper';
      EXPORT Description := 'Small macros to make your ECL more dapper. Transform tools simplify verbose operations into descriptive verbs, string tools makes matching and regex easier.';
      EXPORT Authors := ['Rob Mansfield (rob.mansfield@proagrica.com)'];
      EXPORT License := 'https://www.gnu.org/licenses/gpl-3.0.en.html';
      EXPORT Copyright := 'Copyright (C) 2018 Proagrica';
      EXPORT DependsOn := [];
      EXPORT Version := '0.1.1';
      EXPORT PlatformVersion := '6.0.0';
    END;
    
    EXPORT transformtools := $.transformtools;
    EXPORT stringtools    := $.stringtools;
END;