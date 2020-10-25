function buildProtos() {
    
    
    docker run -v ${pwd}:/defs namely/protoc-all -f protos/allergen-service/AllergenService.proto -l csharp


}
