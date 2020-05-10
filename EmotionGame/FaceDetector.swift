//
//  FaceDetector.swift
//  EmotionGame
//
//  Created by Edward Beckett on 28/11/2019.
//  Copyright © 2019 Ed Beckett. All rights reserved.
//

import Foundation
import AVFoundation
import Vision
import SpriteKit

class FaceDetector {
    
    // class that controls the classification of facial expressions
    var defaults = UserDefaults.standard
    var expression = String()
    
    // the main controlling method
    func findFace(image: CGImage, orientation: CGImagePropertyOrientation) {
        let imageHandler = VNImageRequestHandler(cgImage: image, orientation: orientation, options: [:])
        
        let request = VNDetectFaceRectanglesRequest{request, error in
            if let results=request.results as? [VNFaceObservation]{
                print(results.count, "faces found")
                for _ in results {
                    
                    let faceLandmarks = VNDetectFaceLandmarksRequest()
                    faceLandmarks.inputFaceObservations = results
                    
                    // transformations
                    let tf=CGAffineTransform.init(scaleX: 1, y: -1).translatedBy(x: 0, y: CGFloat(-image.width))
                    let ts=CGAffineTransform.identity.scaledBy(x: CGFloat(image.height), y: CGFloat(image.width))
                    
                    var innerLips, outerLips, leftEye, rightEye, leftEyebrow, rightEyebrow, nose: VNFaceLandmarkRegion2D
                    
                    // slightly backwards as there are rotation issues
                    let size = CGSize(width: image.height, height: image.width)
                    UIGraphicsBeginImageContextWithOptions(size, false, 1.0)
                    
                    try? imageHandler.perform([faceLandmarks])
                    if let landmarksResults = faceLandmarks.results as? [VNFaceObservation] {
                        for observation in landmarksResults {
                            
                            let rect = observation.boundingBox
                            let converted_rect=rect.applying(ts).applying(tf)
                            let rotated_rect = self.rotateRect(converted_rect)
                            let size = CGSize(width: rotated_rect.width, height: rotated_rect.height)
                            
                            // Mouth
                            innerLips = (observation.landmarks?.innerLips)!
                            outerLips = (observation.landmarks?.outerLips)!
                            
                            // Eyes
                            leftEye = (observation.landmarks?.leftEye)!
                            rightEye = (observation.landmarks?.rightEye)!
                            
                            // Eyebrows
                            leftEyebrow = (observation.landmarks?.leftEyebrow)!
                            rightEyebrow = (observation.landmarks?.rightEyebrow)!
                            
                            nose = (observation.landmarks?.nose)!
                            
                            
                            
                            
                            
                            if (self.defaults.bool(forKey: "Method") == false) {
                                // Method 1
                                print("Method 1")
                                let mouthresult = self.mouth(outer: outerLips, inner: innerLips, imageSize: size)
                                
                                // swap eyes around - they are flipped - although does not matter if averaged.
                                let eyeresult = self.eyes(left: rightEye, right: leftEye, imageSize: size)
                                
                                let eyebrowresult = self.eyebrows(left: rightEyebrow, right: leftEyebrow, nose: nose, imageSize: size)
                                
                                self.updateExpression(result: self.classify(eyebrows: eyebrowresult, eyes: eyeresult, mouth: mouthresult))
                            } else {
                                //  Method 2
                                print("Method 2")
                                self.updateExpression(result: self.activeShapeModel(outerMouth: outerLips, innerMouth: innerLips, leftBrow: leftEyebrow, rightBrow: rightEyebrow, leftEye: leftEye, rightEye: rightEye, nose: nose, imageSize: size))
                            }
                        }
                    }
                }
            }
        }
        
        do {
            try imageHandler.perform([request])
        } catch let error as NSError {
            print("Failed to perform image request: \(error)")
            return
        }
    }
    
    func rotateRect(_ rect: CGRect) -> CGRect {
        let x = rect.midX
        let y = rect.midY
        let transform = CGAffineTransform(translationX: x, y: y)
            .rotated(by: .pi / 2)
            .translatedBy(x: -x, y: -y)
        return rect.applying(transform)
    }
    
    
    func activeShapeModel(outerMouth: VNFaceLandmarkRegion2D, innerMouth: VNFaceLandmarkRegion2D, leftBrow: VNFaceLandmarkRegion2D, rightBrow: VNFaceLandmarkRegion2D, leftEye: VNFaceLandmarkRegion2D, rightEye: VNFaceLandmarkRegion2D, nose: VNFaceLandmarkRegion2D, imageSize: CGSize) -> String {
        
        let restingFace = [(0.3660665452480316, 0.2953364849090576), (0.40174901485443115, 0.3226698040962219), (0.4421705901622772, 0.34052014350891113), (0.4828709065914154, 0.33103713393211365), (0.523571252822876, 0.33996230363845825), (0.5709620118141174, 0.3226698040962219), (0.6155651211738586, 0.296452134847641), (0.6534777879714966, 0.2668875455856323), (0.6055294275283813, 0.22783994674682617), (0.5469878911972046, 0.20162227749824524), (0.4839859902858734, 0.19269710779190063), (0.4285108745098114, 0.19994880259037018), (0.37721729278564453, 0.22449299693107605), (0.33902591466903687, 0.26242494583129883), (0.42460811138153076, 0.2774861752986908), (0.4828709065914154, 0.2769283354282379), (0.5520057082176208, 0.27915963530540466), (0.5522844791412354, 0.2719079256057739), (0.4837072193622589, 0.26632970571517944), (0.4262807071208954, 0.27023446559906006), (0.1600559502840042, 0.7957034707069397), (0.27560585737228394, 0.8632000088691711), (0.40983331203460693, 0.8496728539466858), (0.4076031744480133, 0.7993293404579163), (0.28271448612213135, 0.8096490502357483), (0.16660703718662262, 0.7669756412506104), (0.8809536099433899, 0.8182953000068665), (0.741568922996521, 0.8874652981758118), (0.5876882076263428, 0.8651524186134338), (0.592706024646759, 0.8107646703720093), (0.735993504524231, 0.831961989402771), (0.8737055659294128, 0.7890096306800842), (0.2519104778766632, 0.6975266933441162), (0.29442280530929565, 0.7290436625480652), (0.3655090034008026, 0.7296015024185181), (0.41122716665267944, 0.7014314532279968), (0.3638363778591156, 0.6869280338287354), (0.2983255684375763, 0.6802341938018799), (0.7716760039329529, 0.7114722728729248), (0.7226125597953796, 0.740757942199707), (0.6473448276519775, 0.7376899123191833), (0.6010691523551941, 0.7067307829856873), (0.6523627042770386, 0.6952953934669495), (0.7231701016426086, 0.6913906335830688)]
        
        let smilingFace = [(0.3725067675113678, 0.32459232211112976), (0.41280636191368103, 0.33453425765037537), (0.45282989740371704, 0.33950522541999817), (0.4925774335861206, 0.32845863699913025), (0.5331529974937439, 0.33453425765037537), (0.5814573168754578, 0.3229353427886963), (0.6300376057624817, 0.3080224096775055), (0.6764097213745117, 0.2925571799278259), (0.6228609681129456, 0.2478184551000595), (0.5577191710472107, 0.2179926335811615), (0.48760896921157837, 0.21026001870632172), (0.4263315498828888, 0.22351592779159546), (0.37278279662132263, 0.2605220377445221), (0.33441540598869324, 0.3102317452430725), (0.42991986870765686, 0.2964234948158264), (0.4909212589263916, 0.28592923283576965), (0.5654478669166565, 0.28869086503982544), (0.5648958086967468, 0.2831675708293915), (0.489265114068985, 0.27874892950057983), (0.4271596074104309, 0.29090020060539246), (0.14768484234809875, 0.7960059642791748), (0.2756221890449524, 0.8626998066902161), (0.41832682490348816, 0.841573178768158), (0.41446250677108765, 0.791034996509552), (0.28141871094703674, 0.8078810572624207), (0.15458545088768005, 0.7678371667861938), (0.8922608494758606, 0.8222416639328003), (0.7525925040245056, 0.8842406868934631), (0.6013310551643372, 0.8551052808761597), (0.607403576374054, 0.8015292882919312), (0.7487281560897827, 0.8292838335037231), (0.8861883282661438, 0.7935205101966858), (0.2520220875740051, 0.7029383778572083), (0.2988082468509674, 0.7291740775108337), (0.3708506226539612, 0.7272409200668335), (0.4172227382659912, 0.7004528641700745), (0.3678143620491028, 0.6896824240684509), (0.29991233348846436, 0.6852638125419617), (0.7829551696777344, 0.7109471559524536), (0.7332707643508911, 0.7382875084877014), (0.6587441563606262, 0.7333165407180786), (0.6123720407485962, 0.7026622295379639), (0.6642646193504333, 0.6935487389564514), (0.7349269390106201, 0.690787136554718)]
        
        let angryFace = [(0.381265789270401, 0.2966783940792084), (0.4166402220726013, 0.3245464563369751), (0.4564712941646576, 0.34126731753349304), (0.4960238039493561, 0.33123481273651123), (0.5361334085464478, 0.3401525914669037), (0.5804210901260376, 0.32287436723709106), (0.6216448545455933, 0.2961210310459137), (0.6545124650001526, 0.2654661536216736), (0.6105033159255981, 0.22533611953258514), (0.5536813735961914, 0.19914013147354126), (0.4940740466117859, 0.1907797008752823), (0.44003748893737793, 0.1980254054069519), (0.3901790380477905, 0.2242213934659958), (0.354247510433197, 0.26379406452178955), (0.43808773159980774, 0.27995753288269043), (0.4951882064342499, 0.27940016984939575), (0.5603663325309753, 0.27995753288269043), (0.5586950778961182, 0.27215448021888733), (0.4949096739292145, 0.2682529389858246), (0.43975895643234253, 0.27215448021888733), (0.16525886952877045, 0.794959545135498), (0.28795525431632996, 0.8481875658035278), (0.42221102118492126, 0.8295159935951233), (0.4191470742225647, 0.7829762697219849), (0.2924118638038635, 0.7960742712020874), (0.1705511063337326, 0.766812801361084), (0.8628595471382141, 0.8180900812149048), (0.7263755202293396, 0.8665804862976074), (0.5832064747810364, 0.8396878242492676), (0.5893343687057495, 0.7905006408691406), (0.7241472005844116, 0.8139098286628723), (0.8584029078483582, 0.7891072630882263), (0.25202372670173645, 0.7180436849594116), (0.2963114082813263, 0.743960976600647), (0.3659461438655853, 0.7434036135673523), (0.41106945276260376, 0.7177649736404419), (0.36316075921058655, 0.7071751356124878), (0.29770413041114807, 0.7013228535652161), (0.7687134146690369, 0.7261254191398621), (0.7208046913146973, 0.7512066960334778), (0.6494987607002258, 0.7481411695480347), (0.6049325466156006, 0.7199944257736206), (0.6545124650001526, 0.7116340398788452), (0.7224759459495544, 0.7077324986457825)]
        
        let surprisedFace = [(0.37572184205055237, 0.2808384299278259), (0.4048863351345062, 0.3272871673107147), (0.448633074760437, 0.3558710217475891), (0.48880866169929504, 0.3469385802745819), (0.5295794010162354, 0.3540845215320587), (0.580468475818634, 0.32430967688560486), (0.6197512745857239, 0.278456449508667), (0.6423686146736145, 0.22605271637439728), (0.6102281808853149, 0.1617390662431717), (0.5545775890350342, 0.1152903139591217), (0.4852374792098999, 0.09980739653110504), (0.42452773451805115, 0.11826779693365097), (0.38167375326156616, 0.16650304198265076), (0.36530593037605286, 0.22783920168876648), (0.4322652518749237, 0.2856023907661438), (0.48880866169929504, 0.2963213324546814), (0.5572559237480164, 0.28441140055656433), (0.552791953086853, 0.18972741067409515), (0.48583269119262695, 0.17841297388076782), (0.4331580400466919, 0.19270490109920502), (0.1803494691848755, 0.8021959066390991), (0.28376439213752747, 0.8738043904304504), (0.40994545817375183, 0.8691892623901367), (0.40935027599334717, 0.8209540247917175), (0.2923946976661682, 0.8242292404174805), (0.18689660727977753, 0.7751007676124573), (0.859614372253418, 0.8309286236763), (0.7375996708869934, 0.9000062346458435), (0.5977290868759155, 0.8843744397163391), (0.6013002991676331, 0.8334594368934631), (0.7316477298736572, 0.8495378494262695), (0.8530672192573547, 0.8033868670463562), (0.2659085690975189, 0.6950064301490784), (0.3054889738559723, 0.7295452952384949), (0.3748290538787842, 0.730140745639801), (0.41857579350471497, 0.7009614109992981), (0.37334105372428894, 0.6833942532539368), (0.3105481266975403, 0.67624831199646), (0.7649785876274109, 0.7092983722686768), (0.7197438478469849, 0.7417529225349426), (0.6465349793434143, 0.7393709421157837), (0.6036810278892517, 0.7060231566429138), (0.6524869203567505, 0.6914334893226624), (0.7197438478469849, 0.6875627636909485)]
        
        let outerMouthPoints = outerMouth.normalizedPoints
        let innerMouthPoints = innerMouth.normalizedPoints
        let leftBrowPoints = leftBrow.normalizedPoints
        let rightBrowPoints = rightBrow.normalizedPoints
        let leftEyePoints = leftEye.normalizedPoints
        let rightEyePoints = rightEye.normalizedPoints
        
        let faceVector = outerMouthPoints + innerMouthPoints + leftBrowPoints + rightBrowPoints + leftEyePoints + rightEyePoints
        
        //print(faceVector)
        
        // may need to look at rotation??
        var error = CGFloat(10)
        var lowestError = "Neutral"
        var result = compare(facePresent: faceVector, faceStored: restingFace)
        if result < error {
            error = result
            lowestError = "Neutral"
        }
        result = compare(facePresent: faceVector, faceStored: smilingFace)
        if result < error {
            error = result
            lowestError = "Happy"
        }
        result = compare(facePresent: faceVector, faceStored: angryFace)
        if result < error {
            error = result
            lowestError = "Angry"
        }
        result = compare(facePresent: faceVector, faceStored: surprisedFace)
        if result < error {
            error = result
            lowestError = "Surprised"
        }
        print(lowestError)
        
        return lowestError
    }
    
    func compare(facePresent: [CGPoint], faceStored: [(Double, Double)]) -> CGFloat {
        var error = CGFloat(0)
        for x in 0...facePresent.count-1 {
            // previous method
            // let xErr = facePresent[x].x - CGFloat(faceStored[x].0)
            // let yErr = facePresent[x].y - CGFloat(faceStored[x].1)
            // error += pow(xErr.magnitude + yErr.magnitude,2)
            // error += xErr.magnitude + yErr.magnitude
            
            // euclidian distance between point and expected location
            // converted to positive for better "error" measure
            // then squared so that the error is a sum of squared errors, meaning that the big errors get bigger and the little errors get smaller
            error += pow((pow(facePresent[x].x - CGFloat(faceStored[x].0),2) + pow(facePresent[x].y - CGFloat(faceStored[x].1),2)).squareRoot().magnitude,2)
        }
        //print(error)
        return error
    }
    // Expression detection
    // could potentially place this in another file...
    
    // Surprise = raised and curved eyebrows, eyes opened, mouth open
    // Fear = eyebrows raised and close, eyes open, mouth open
    // Anger = eyebrows lower and together, mouth closed?
    // Happiness = corners of mouth up, mouth may be open
    
    // might just want surprise/fear, anger/sadness and happiness?
    
    func mouth(outer: VNFaceLandmarkRegion2D, inner: VNFaceLandmarkRegion2D, imageSize: CGSize) -> String {
        // tidy up and comment
        
        // open/closed mouth
        // corners of mouth?
        var mouthOpen = false
        var cornersUp = false
        var result = ""
        
        var minWidth = CGFloat(5000)
        var maxWidth = CGFloat(0)
        var minHeight = CGFloat(5000)
        var maxHeight = CGFloat(0)
        
        for i in 0...inner.pointsInImage(imageSize: imageSize).count - 1 {
            let point = inner.pointsInImage(imageSize: imageSize)[i]
            
            if (point.x > maxWidth) {
                maxWidth = point.x
            }
            
            if (point.x < minWidth) {
                minWidth = point.x
            }
            
            if (point.y > maxHeight) {
                maxHeight = point.y
            }
            
            if (point.y < minHeight) {
                minHeight = point.y
            }
        }
        
        let width = maxWidth - minWidth
        let height = maxHeight - minHeight
        
        // seems to work
        if (height > (width/4)) {
            mouthOpen = true
        }
        
        var points = outer.pointsInImage(imageSize: imageSize)
        points.sort { $0.x < $1.x }
        
        // A -> B -> C
        // 0 = B
        // 1 = A
        // 2 = C
        let vectorBA = CGPoint(x: (points[1].x - points[0].x),y: (points[1].y - points[0].y))
        let vectorBC = CGPoint(x: (points[2].x - points[0].x),y: (points[2].y - points[0].y))
        let Ldot = (vectorBA.x * vectorBC.x) + (vectorBA.y * vectorBC.y)
        let LangleRad = Ldot / ((pow(vectorBA.x,2) + pow(vectorBA.y,2)).squareRoot() * (pow(vectorBC.x,2) + pow(vectorBC.y,2)).squareRoot())
        let Langle = acos(LangleRad)*180/CGFloat.pi
        //print(Langle)
        
        // D -> E -> F
        // points.count - 1 = e
        // points.count - 2 = d
        // points.count - 3 = f
        let vectorED = CGPoint(x: (points[points.count - 2].x - points[points.count - 1].x),y: (points[points.count - 2].y - points[points.count - 1].y))
        let vectorEF = CGPoint(x: (points[points.count - 3].x - points[points.count - 1].x),y: (points[points.count - 3].y - points[points.count - 1].y))
        let Rdot = (vectorED.x * vectorEF.x) + (vectorED.y * vectorEF.y)
        let RangleRad = Rdot / ((pow(vectorED.x,2) + pow(vectorED.y,2)).squareRoot() * (pow(vectorEF.x,2) + pow(vectorEF.y,2)).squareRoot())
        let Rangle = acos(RangleRad)*180/CGFloat.pi
        //print(Rangle)
        
        let angle = (Langle + Rangle) / 2
        //print(angle)
        if angle > 60 {
            //print("(ANGLE) Not smiling")
            cornersUp = false
        } else {
            //print("(ANGLE) Smiling")
            cornersUp = true
        }
        
        // compute dot product then get angle
        // potentially for both sides and average angle? this should remove some issues with face pos
        
        // ADJUST - phone looking up / down affects it.
        // Can solve roll angle issues by requiring both
        // this works unless the phone is higher than the face. - not common
        
        // something to do with the majority of points being over the mean means its a bad angle???
        
        // doesnt work with mouth open & smiling...
        
        if (mouthOpen) {
            result += "Mouth Open "
        } else {
            result += "Mouth Closed "
        }
        
        if (cornersUp) {
            result += "Smiling"
        } else {
            //result += "Not Smiling"
        }
        
        print(result)
        return result
    }
    
    func eyes(left: VNFaceLandmarkRegion2D, right: VNFaceLandmarkRegion2D, imageSize: CGSize) -> String {
        // simplify and comment
        
        var result = ""
        
        var LminWidth = CGFloat(5000)
        var LmaxWidth = CGFloat(0)
        var LminHeight = CGFloat(5000)
        var LmaxHeight = CGFloat(0)
        
        var RminWidth = CGFloat(5000)
        var RmaxWidth = CGFloat(0)
        var RminHeight = CGFloat(5000)
        var RmaxHeight = CGFloat(0)
        
        // left eye
        for i in 0...left.pointsInImage(imageSize: imageSize).count - 1 {
            let point = left.pointsInImage(imageSize: imageSize)[i]
            
            if (point.x > LmaxWidth) {
                // corner point 1
                LmaxWidth = point.x
            }
            
            if (point.x < LminWidth) {
                // corner point 2
                LminWidth = point.x
            }
            
            if (point.y > LmaxHeight) {
                // top point
                LmaxHeight = point.y
            }
            
            if (point.y < LminHeight) {
                // bottom point
                LminHeight = point.y
            }
        }
        
        let Lwidth = LmaxWidth - LminWidth
        let Lheight = LmaxHeight - LminHeight
        
        // right eye
        for i in 0...right.pointsInImage(imageSize: imageSize).count - 1 {
            let point = right.pointsInImage(imageSize: imageSize)[i]
            
            if (point.x > RmaxWidth) {
                RmaxWidth = point.x
            }
            
            if (point.x < RminWidth) {
                RminWidth = point.x
            }
            
            if (point.y > RmaxHeight) {
                RmaxHeight = point.y
            }
            
            if (point.y < RminHeight) {
                RminHeight = point.y
            }
        }
        
        let Rwidth = RmaxWidth - RminWidth
        let Rheight = RmaxHeight - RminHeight
        
        // simplified to classify both eyes as one.
        // take each eye's height and width and get mean values
        // then get the width/height ratio
        let wxh = Double((Lwidth+Rwidth/2)/(Lheight+Rheight/2))
        
        if (wxh < 5.25) {
            result += "Eyes Open "
        } else if (wxh > 5.25) {
            result += "Eyes Closed "
        }
        /*
         // left eye classification
         let lwxh = Double(Lwidth/Lheight)
         //print(lwxh)
         
         if (lwxh < 5.25) {
         result += "Left Eye Open "
         } else if (lwxh > 5.25) {
         result += "Left Eye Closed "
         }
         
         // right eye classification
         let rwxh = Double(Rwidth/Rheight)
         //print(rwxh)
         
         if (rwxh < 5.25) {
         result += "Right Eye Open "
         } else if (rwxh > 5.25) {
         result += "Right Eye Closed "
         }
         */
        print(result)
        return result
    }
    
    // Eyebrows
    func eyebrows(left: VNFaceLandmarkRegion2D, right: VNFaceLandmarkRegion2D, nose: VNFaceLandmarkRegion2D, imageSize: CGSize) -> String {
        var result = ""
        
        var LminWidth = CGFloat(5000)
        var LmaxWidth = CGFloat(0)
        var LminHeight = CGFloat(5000)
        var LmaxHeight = CGFloat(0)
        
        var RminWidth = CGFloat(5000)
        var RmaxWidth = CGFloat(0)
        var RminHeight = CGFloat(5000)
        var RmaxHeight = CGFloat(0)
        
        for i in 0...left.pointsInImage(imageSize: imageSize).count - 1 {
            let point = left.pointsInImage(imageSize: imageSize)[i]
            
            if (point.x > LmaxWidth) {
                LmaxWidth = point.x
            }
            
            if (point.x < LminWidth) {
                LminWidth = point.x
            }
            
            if (point.y > LmaxHeight) {
                LmaxHeight = point.y
            }
            
            if (point.y < LminHeight) {
                LminHeight = point.y
            }
            
            print(point)
        }
        
        let Lwidth = LmaxWidth - LminWidth
        let Lheight = LmaxHeight - LminHeight
        
        
        for i in 0...right.pointsInImage(imageSize: imageSize).count - 1 {
            let point = right.pointsInImage(imageSize: imageSize)[i]
            
            if (point.x > RmaxWidth) {
                RmaxWidth = point.x
            }
            
            if (point.x < RminWidth) {
                RminWidth = point.x
            }
            
            if (point.y > RmaxHeight) {
                RmaxHeight = point.y
            }
            
            if (point.y < RminHeight) {
                RminHeight = point.y
            }
        }
        
        let Rwidth = RmaxWidth - RminWidth
        let Rheight = RmaxHeight - RminHeight
        
        let avgwidth = (Lwidth + Rwidth) / 2
        let avgheight = (Lheight + Rheight) / 2
        
        if (avgwidth/avgheight < 3.25) {
            // raised
            print("Eyebrows Raised")
            result += "Eyebrows Raised "
        } else if ((avgwidth/avgheight >= 3.25) && (avgwidth/avgheight < 3.6)) {
            // normal
            print("Eyebrows Normal")
            result += "Eyebrows Normal "
        } else if (avgwidth/avgheight >= 3.6) {
            // close
            print("Eyebrows Close")
            result += "Eyebrows Close "
        }
        
        return result
    }
    
    func classify(eyebrows: String, eyes: String, mouth: String) -> String {
        // Surprise/Fear = raised eyebrows, eyes opened, mouth open
        
        // Anger = eyebrows lower and together, mouth closed?
        
        // Happiness = corners of mouth up, mouth may be open
        
        // Neutral = all normal
        
        var emotion = ""
        
        if mouth.contains("Smiling") {
            emotion = "Happy"
        } else if eyebrows.contains("Eyebrows Close") && mouth.contains("Mouth Closed") {
            emotion = "Angry"
        } else if eyebrows.contains("Eyebrows Raised") {
            emotion = "Surprised"
        } else if mouth.contains("Mouth Open") {
            emotion = "Surprised"
        } else {
            emotion = "Neutral"
        }
        
        // consider using eyes closed?
        
        print(emotion + " detected \n")
        return emotion
    }
    
    func updateExpression(result: String) {
        expression = result
        //print("Expression Updated")
    }
    
    func getExpression() -> String {
        return expression
    }
}

