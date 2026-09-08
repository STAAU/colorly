import Foundation

enum SampleContent {
    static let categories = [
        ColoringCategory(id: "animals", title: "Animals", symbol: "pawprint.fill", sortOrder: 0),
        ColoringCategory(id: "dinosaurs", title: "Dinosaurs", symbol: "fossil.shell.fill", sortOrder: 1),
        ColoringCategory(id: "vehicles", title: "Vehicles", symbol: "car.fill", sortOrder: 2),
        ColoringCategory(id: "space", title: "Space", symbol: "sparkles", sortOrder: 3),
        ColoringCategory(id: "ocean", title: "Ocean", symbol: "fish.fill", sortOrder: 4),
        ColoringCategory(id: "fantasy", title: "Fantasy", symbol: "wand.and.stars", sortOrder: 5),
        ColoringCategory(id: "cute", title: "Cute", symbol: "heart.fill", sortOrder: 6),
        ColoringCategory(id: "food", title: "Food", symbol: "birthday.cake.fill", sortOrder: 7)
    ]
    static let pages: [ColoringPage] = {
        let values: [(String,String,String,ColoringDifficulty,Bool,Bool)] = [
            ("cat","Cat","animals",.easy,false,true),("dog","Dog","animals",.easy,false,true),
            ("panda","Panda","animals",.medium,true,false),("fox","Fox","animals",.medium,false,false),
            ("trex","T-Rex","dinosaurs",.medium,true,true),("triceratops","Triceratops","dinosaurs",.detailed,false,false),
            ("car","Car","vehicles",.easy,false,true),("fire-truck","Fire Truck","vehicles",.detailed,true,false),
            ("rocket","Rocket","space",.easy,false,true),("astronaut","Astronaut","space",.detailed,true,false),("planet","Planet","space",.medium,false,false),
            ("fish","Fish","ocean",.easy,false,false),("turtle","Turtle","ocean",.medium,false,false),
            ("dragon","Dragon","fantasy",.detailed,true,true),("unicorn","Unicorn","cute",.medium,true,false),
            ("cupcake","Cupcake","food",.easy,false,true)
        ]
        return values.enumerated().map { i, v in ColoringPage(id:v.0,title:v.1,categoryID:v.2,sourceKey:v.0,thumbnailKey:v.0,difficulty:v.3,isPremium:v.4,isFeatured:v.5,sortOrder:i) }
    }()
}
