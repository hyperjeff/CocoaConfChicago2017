import Cocoa
import Metal
import SceneKit


class ViewController: NSViewController {
	
	@IBOutlet weak var sceneView: SCNView!
	
	let side = 11
	let radius: CGFloat = 1
	
	var lifeTracker: LifeTracker!
	var sphereNodes: [SCNNode] = []
	var othelloNodes: SCNNode! = nil
	var timerCells, timerBoard: Timer!
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		lifeTracker = LifeTracker(side: side)
		setupSceneView()
		
		let area = side * side
		var sceneRotation: CGFloat = 0
		
		timerCells = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
			
			SCNTransaction.begin()
			SCNTransaction.animationDuration = 0.5

			let data = self.lifeTracker.cellCurrentBuffer.contents().bindMemory(to: Bool.self, capacity: area)
			for i in 0 ..< area {
				self.sphereNodes[i].rotation = SCNVector4Make(0, 1, 0,
					(data[i] ? 1 : -1) * CGFloat.pi / 2
				)
			}
			
			SCNTransaction.commit()
			
			self.lifeTracker.update()
		}
		
		timerBoard = Timer.scheduledTimer(withTimeInterval: 1/30.0, repeats: true) { _ in
			SCNTransaction.begin()
			SCNTransaction.animationDuration = 1/30.0
			
			self.othelloNodes.rotation = SCNVector4Make(0, 1, 0, sceneRotation)
			
			SCNTransaction.commit()
			sceneRotation += 0.003
		}
	}

	func setupSceneView() {
		let scene = SCNScene()
		
		let cameraNode = SCNNode()
		cameraNode.camera = SCNCamera()
		cameraNode.position = SCNVector3Make(0, 5, 20)
		
		
		let spotlight = SCNLight()
		spotlight.type = .spot
		spotlight.color = NSColor(calibratedWhite: 0.4, alpha: 1)
		spotlight.spotInnerAngle = 60
		spotlight.spotOuterAngle = 100
		spotlight.castsShadow = true
		
		let spotlightNode = SCNNode()
		spotlightNode.light = spotlight
		spotlightNode.position = SCNVector3Make(-30, 25, 30)
		spotlightNode.constraints = [SCNLookAtConstraint(target: scene.rootNode)]
		
		
		let directional = SCNLight()
		directional.type = .directional
		directional.color = NSColor(calibratedWhite: 0.3, alpha: 1)
		
		let directionalNode = SCNNode()
		directionalNode.light = directional
		directionalNode.rotation = SCNVector4Make(0, 1, 0, -CGFloat.pi/4)
		
		
		let ambient = SCNLight()
		ambient.type = .ambient
		ambient.color = NSColor.init(calibratedWhite: 0.25, alpha: 1)
		
		let ambientNode = SCNNode()
		ambientNode.light = ambient
		
		
		let floor = SCNFloor()
		floor.firstMaterial?.diffuse.contents = NSColor.white
		floor.firstMaterial?.lightingModel = .constant
		floor.reflectivity = 0.15
		floor.reflectionFalloffEnd = 15
		
		let floorNode = SCNNode(geometry: floor)
		
		
		let marbleMaterial = SCNMaterial()
		marbleMaterial.diffuse.contents = NSImage(named: "marble.jpg")
		marbleMaterial.specular.contents = NSColor.lightGray
		marbleMaterial.shininess = 0.15
		marbleMaterial.locksAmbientWithDiffuse = true
		
		
		othelloNodes = SCNNode()
		othelloNodes.position = SCNVector3Make(0, 0.5, 0)
		
		let sphere = SCNSphere()
		sphere.radius = radius
		sphere.firstMaterial = marbleMaterial
		
		let radius™ = radius * 2.2
		
		for x in 0 ..< side {
			for y in 0 ..< side {
				let sphereNode = SCNNode(geometry: sphere)
				sphereNode.position = SCNVector3Make(
					(CGFloat(x) - CGFloat(side)/2) * radius™,
					CGFloat(y) * radius™ + radius™,
					0
				)
				sphereNode.scale = SCNVector3Make(0.2, 1, 1)
				sphereNode.rotation = SCNVector4Make(0, 1, 0, CGFloat.pi / 2)
				
				othelloNodes.addChildNode(sphereNode)
				sphereNodes.append(sphereNode)
			}
		}
		
		let midIndex = (side - 1)/2 * (1 + side) - 1
		let constraint = SCNLookAtConstraint(target: sphereNodes[midIndex])
		cameraNode.constraints = [ constraint ]
		
		for node in [cameraNode, spotlightNode, directionalNode, ambientNode, floorNode, othelloNodes!] {
			scene.rootNode.addChildNode(node)
		}
		sceneView.scene = scene
	}
	
	func reset() {
		lifeTracker.setupBuffers()
	}
}

