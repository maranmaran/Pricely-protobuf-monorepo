docker run -v ${pwd}:/defs namely/protoc-all -f other/protos/AllergenService.proto -l csharp

docker run -v ${pwd}:/defs namely/protoc-all -f other/protos/AllergenMessages.proto -l csharp

