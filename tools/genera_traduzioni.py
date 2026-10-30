#!/usr/bin/env python3
"""Genera content/i18n/en.json e content/i18n/es.json.

I contenuti tecnici originali sono in italiano (content/*.json). Qui stanno le traduzioni, scritte da Claude,
con gli stessi contenuti e gli stessi consigli: non si aggiunge nulla che non sia già nell'originale italiano
(le fonti restano quelle dell'originale, in content/fonti.json). Il test ContentStoreTests verifica che
ogni testo visibile agli utenti abbia la traduzione.

Uso: python3 tools/genera_traduzioni.py
"""
import glob
import json
import os
import re

RADICE = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..")
CONTENT = os.path.join(RADICE, "content")

# ---------------------------------------------------------------- drill
# id -> (nome, scopo, esecuzione, errore_da_evitare)
DRILL = {"en": {}, "es": {}}

DRILL["en"] = {
"galleggiamento-a-stella": ("Star float",
 "Feel that the water supports you and learn to relax.",
 "In water where you can touch the bottom, fill your lungs and let yourself float face down with your arms and legs spread out like a star. Then try on your back. To stand up, bring your knees to your chest and put your feet down. Other useful positions: the jellyfish and the tuck.",
 "Stiffening up and keeping your head high: your body sinks."),
"bolle-in-acqua": ("Blowing bubbles",
 "Learn to breathe out in the water.",
 "Standing in shallow water, put your face in and blow air out through your nose and mouth in a continuous stream. Lift your face, breathe in and repeat at a steady rhythm.",
 "Holding your breath underwater."),
"respirazione-al-bordo": ("Breathing at the wall",
 "Coordinate breathing out and breathing in while turning your head.",
 "Hold the wall with your hands. Put your face in and breathe out, then turn your head to the side to breathe in with your mouth just out of the water and put your face back in. Repeat at a steady rhythm, on both sides.",
 "Lifting your head forward instead of turning it to the side."),
"scivolamento-a-freccia": ("Streamline glide",
 "Find a long body position that glides well.",
 "Push off the wall with your feet, arms stretched out in front, head between your arms and body flat, face down and then on your back. Glide until you lose speed, then put your feet down.",
 "Losing alignment: head up or legs sinking."),
"battuta-con-tavoletta": ("Kickboard kick",
 "Train the leg kick in a simple way.",
 "Hold the kickboard with your arms straight, with your body horizontal. Kick continuously from the hip, with your feet close to the surface. The kickboard is optional.",
 "Pedalling with too much knee bend."),
"battuta-con-un-braccio-teso": ("One-arm-extended kick",
 "Lengthen the body and prepare the body roll.",
 "One arm stretched out in front and the other along your side. Roll your hips and shoulders to about 45 degrees, keeping your head still, and kick continuously.",
 "Rolling too far or moving your head."),
"catch-up": ("Catch-up",
 "Lengthen the stroke and coordinate the arms.",
 "Swim freestyle, but one hand only starts when the other has reached it out in front. Enter the water with your fingertips first and let your hand glide forward.",
 "Rushing the strokes like windmill paddles, with the arms moving in opposition."),
"un-braccio-solo": ("Single-arm drill",
 "Work on the stroke and the body roll, one arm at a time.",
 "One arm stays along your side or stretched out in front while the other does the stroke. Switch sides after a few strokes and keep kicking.",
 "Stopping your body or losing your head position while one arm works."),
"dita-sull-acqua": ("Fingertip drag",
 "Have a relaxed recovery with a high elbow.",
 "Swim catch-up and, during the recovery, trail your fingertips along the surface of the water.",
 "A low elbow and a stiff recovery."),
"respirazione-laterale-con-tavoletta": ("Side breathing with a kickboard",
 "Learn to breathe to the side while swimming.",
 "Hold the kickboard with one arm. With the other arm do the stroke and turn your head together with your body to breathe, while your legs kick. Then switch arms.",
 "Lifting your head instead of turning it with your body."),
"sei-colpi-e-cambio": ("Six kicks and switch",
 "Control the body roll and lengthen the stroke.",
 "Six kicks on one side, with one arm stretched out in front and the other along your body. Then one stroke with the extended arm and a roll onto the other side, and six more kicks. You can do it with fins.",
 "Losing the kick during the switch."),
"nuotata-con-pull-buoy": ("Pull buoy swim",
 "Focus on the arms and an aligned body.",
 "Hold the pull buoy between your thighs and swim freestyle using only your arms, at an easy pace.",
 "Losing the alignment of your body and head."),
"battuta-sul-dorso": ("Backstroke kick",
 "Position and kick in backstroke.",
 "On your back, with your arms along your sides, look up and slightly towards your feet, with your head aligned and your shoulders low. Kick from the hip, with little knee bend.",
 "Arching your back and opening your ribs."),
"dorso-un-braccio-alla-volta": ("One-arm backstroke",
 "Work on the stroke and the body roll in backstroke.",
 "On your back, one arm stretched out above your head while the other does the stroke, with a continuous kick. Roll your hips and shoulders to about 45 degrees. Switch arms after a few strokes.",
 "Lifting the shoulder towards the chin."),
"gambata-di-rana-al-bordo": ("Breaststroke kick at the wall",
 "Learn the leg movement of breaststroke.",
 "Hold the wall with your arms bent and your body stretched out. Bring your heels towards your buttocks, with your knees just wider than your hips. Turn your feet outwards, flex them and push back in a circular motion, finishing with your legs straight and together.",
 "Feet not turned outwards: it is the most common mistake."),
"rana-con-scivolo": ("Breaststroke with glide",
 "Find the rhythm between pull, kick and glide.",
 "Swim breaststroke following the sequence: pull, breath, kick, glide with your arms stretched out. Count in your head during the glide before the next cycle.",
 "Starting the kick too early or skipping the glide."),
"onda-del-delfino": ("Dolphin wave",
 "Learn the wave-like movement led by the chest.",
 "In the water, press your chest down: your hips rise. Then bring your hips back down and let the movement travel all the way to your feet. Fins and a snorkel help you concentrate on the body movement.",
 "Moving only your legs instead of starting the wave from your chest."),
"dorso-battuta-con-rotazione": ("Backstroke kick with rotation",
 "Learn to roll the body while staying aligned, with the kick starting from the hip.",
 "On your back, with your arms along your sides, look up and a little towards your feet. Kick from the hip and roll your hips and body from side to side, keeping your shoulders low and your head still. At first you can hold a float with your hands at your sides, above your hips; fins can be used.",
 "Lifting your shoulders during the rotation or tilting your head too far back, opening your ribs."),
"gambata-di-rana-sul-dorso": ("Breaststroke kick on the back",
 "Control the leg recovery and the breaststroke push in a stretched-out position.",
 "On your back, stretched out and flat at the surface, bring your feet under your knees keeping your knees at water level. When the recovery is done, turn your feet outwards and push back until your heels and feet come together, with your toes pointed backwards. A pull buoy can help keep your knees in a neutral position.",
 "Letting your knees come out of the water or opening your ribs."),
"rana-due-gambate-una-bracciata": ("Breaststroke: two kicks, one pull",
 "Work on the stretched-out position and breathing by reducing the number of pulls.",
 "Swim breaststroke doing two kicks for every pull. After the breath, bring your head back in line with your body straight away. Push forward staying just below the surface, without going deep, and use the second kick to move ahead like an arrow.",
 "Keeping your head up after the breath or diving too deep."),
"rana-corpo-verso-le-mani": ("Breaststroke: body to the hands",
 "Understand that in the breaststroke pull it is the body that moves forward towards the hands.",
 "Start in a stretched-out position. As soon as your hands open, hold the water with your palms, usually beyond shoulder width, and turn your hands backwards. Bring your body forward towards your hands and return to the stretched-out position after each complete pull. You can do it with a pull buoy.",
 "Pulling your hands towards your body instead of bringing your body towards your hands."),
"delfino-un-braccio-alla-volta": ("One-arm butterfly",
 "Work on the butterfly pull one arm at a time, keeping the undulation.",
 "One arm stays stretched out in front and steadies the body, while the other does the pull and the recovery close to the surface, stretched but relaxed. Breathe forward only on the full strokes with both arms. Switch sides.",
 "Letting the body roll: the front arm is there to keep it steady."),
}

DRILL["es"] = {
"galleggiamento-a-stella": ("Flotación en estrella",
 "Sentir que el agua te sostiene y aprender a relajarte.",
 "En agua donde hagas pie, llena los pulmones y déjate flotar boca abajo con los brazos y las piernas abiertos en forma de estrella. Después prueba boca arriba. Para ponerte de pie, lleva las rodillas al pecho y apoya los pies. Otras posiciones útiles: la medusa y el ovillo.",
 "Ponerse rígido y mantener la cabeza alta: el cuerpo se hunde."),
"bolle-in-acqua": ("Burbujas en el agua",
 "Aprender a soltar el aire en el agua.",
 "De pie en agua poco profunda, mete la cara y suelta el aire por la nariz y por la boca de forma continua. Levanta la cara, inspira y repite con un ritmo regular.",
 "Aguantar la respiración bajo el agua."),
"respirazione-al-bordo": ("Respiración en el borde",
 "Coordinar la espiración y la inspiración girando la cabeza.",
 "Agárrate al borde con las manos. Mete la cara y espira; después gira la cabeza hacia un lado para inspirar con la boca justo fuera del agua y vuelve a meter la cara. Repite con un ritmo regular, hacia los dos lados.",
 "Levantar la cabeza hacia delante en lugar de girarla hacia un lado."),
"scivolamento-a-freccia": ("Deslizamiento en flecha",
 "Encontrar una posición alargada que se deslice bien.",
 "Impúlsate desde el borde con los pies, con los brazos estirados hacia delante, la cabeza entre los brazos y el cuerpo estirado, boca abajo y después boca arriba. Deslízate hasta perder velocidad y apoya los pies.",
 "Perder la alineación: cabeza levantada o piernas que se hunden."),
"battuta-con-tavoletta": ("Patada con tabla",
 "Entrenar la patada de forma sencilla.",
 "Sujeta la tabla con los brazos estirados, con el cuerpo en horizontal. Bate las piernas de forma continua desde la cadera, con los pies cerca de la superficie. La tabla es opcional.",
 "Pedalear doblando demasiado las rodillas."),
"battuta-con-un-braccio-teso": ("Patada con un brazo estirado",
 "Alargar el cuerpo y preparar la rotación.",
 "Un brazo estirado hacia delante y el otro a lo largo del costado. Gira las caderas y los hombros unos 45 grados, manteniendo la cabeza quieta, y bate las piernas de forma continua.",
 "Girar demasiado o mover la cabeza."),
"catch-up": ("Catch-up",
 "Alargar la brazada y coordinar los brazos.",
 "Nada crol, pero una mano solo sale cuando la otra la ha alcanzado delante. Entra en el agua con los dedos primero y deja que la mano se deslice hacia delante.",
 "Apresurar las brazadas como las palas de un molino, con los brazos moviéndose en oposición."),
"un-braccio-solo": ("Un solo brazo",
 "Cuidar la brazada y la rotación del cuerpo, un brazo cada vez.",
 "Un brazo se queda a lo largo del costado o estirado hacia delante mientras el otro hace la brazada. Cambia de lado tras unas cuantas brazadas y sigue batiendo las piernas.",
 "Parar el cuerpo o perder la posición de la cabeza mientras un brazo trabaja."),
"dita-sull-acqua": ("Dedos sobre el agua",
 "Tener una recuperación relajada con el codo alto.",
 "Nada catch-up y, durante la recuperación, arrastra la punta de los dedos por la superficie del agua.",
 "El codo bajo y la recuperación rígida."),
"respirazione-laterale-con-tavoletta": ("Respiración lateral con tabla",
 "Aprender a respirar de lado mientras nadas.",
 "Sujeta la tabla con un brazo. Con el otro haz la brazada y gira la cabeza junto con el cuerpo para respirar, mientras las piernas baten. Después cambia de brazo.",
 "Levantar la cabeza en lugar de girarla con el cuerpo."),
"sei-colpi-e-cambio": ("Seis patadas y cambio",
 "Controlar la rotación y alargar la brazada.",
 "Seis patadas sobre un costado, con un brazo estirado hacia delante y el otro a lo largo del cuerpo. Después una brazada con el brazo estirado y el paso al otro costado, y otras seis patadas. Se puede hacer con aletas.",
 "Perder la patada durante el cambio de lado."),
"nuotata-con-pull-buoy": ("Nado con pull buoy",
 "Concentrarse en los brazos y en el cuerpo alineado.",
 "Sujeta el pull buoy entre los muslos y nada crol usando solo los brazos, a un ritmo fácil.",
 "Perder la alineación del cuerpo y de la cabeza."),
"battuta-sul-dorso": ("Patada de espalda",
 "Posición y patada en la espalda.",
 "Boca arriba, con los brazos a lo largo de los costados, mira hacia arriba y un poco hacia los pies, con la cabeza alineada y los hombros bajos. Bate las piernas desde la cadera, con poca flexión de las rodillas.",
 "Arquear la espalda abriendo las costillas."),
"dorso-un-braccio-alla-volta": ("Espalda a un brazo",
 "Cuidar la brazada y la rotación en la espalda.",
 "Boca arriba, un brazo estirado por encima de la cabeza mientras el otro hace la brazada, con la patada continua. Gira las caderas y los hombros unos 45 grados. Cambia de brazo tras unas cuantas brazadas.",
 "Subir el hombro hacia la barbilla."),
"gambata-di-rana-al-bordo": ("Patada de braza en el borde",
 "Aprender el movimiento de las piernas en la braza.",
 "Agárrate al borde con los brazos doblados y el cuerpo estirado. Lleva los talones hacia los glúteos, con las rodillas un poco más abiertas que las caderas. Gira los pies hacia fuera, flexiónalos y empuja hacia atrás en un movimiento circular, terminando con las piernas estiradas y juntas.",
 "No girar los pies hacia fuera: es el error más frecuente."),
"rana-con-scivolo": ("Braza con deslizamiento",
 "Encontrar el ritmo entre brazada, patada y deslizamiento.",
 "Nada braza respetando la secuencia: brazada, respiración, patada, deslizamiento con los brazos estirados. Cuenta mentalmente durante el deslizamiento antes del ciclo siguiente.",
 "Adelantar la patada o saltarse el deslizamiento."),
"onda-del-delfino": ("Onda del delfín",
 "Aprender el movimiento ondulatorio guiado por el pecho.",
 "En el agua, empuja el pecho hacia abajo: las caderas suben. Después baja las caderas y deja que el movimiento llegue hasta los pies. Las aletas y el tubo ayudan a concentrarse en el movimiento del cuerpo.",
 "Mover solo las piernas en lugar de hacer que la onda parta del pecho."),
"dorso-battuta-con-rotazione": ("Patada de espalda con rotación",
 "Aprender a girar el cuerpo manteniéndose alineado, con la patada que parte de la cadera.",
 "Boca arriba, con los brazos a lo largo de los costados, mira hacia arriba y un poco hacia los pies. Bate las piernas desde la cadera y gira las caderas y el cuerpo de un lado a otro, con los hombros bajos y la cabeza quieta. Al principio puedes sujetar un flotador con las manos a los lados, por encima de las caderas; se pueden usar aletas.",
 "Subir los hombros durante la rotación o inclinar la cabeza demasiado hacia atrás, abriendo las costillas."),
"gambata-di-rana-sul-dorso": ("Patada de braza boca arriba",
 "Controlar la recuperación de las piernas y el impulso de la braza en posición alargada.",
 "Boca arriba, en posición alargada y plana en la superficie, lleva los pies bajo las rodillas manteniendo las rodillas a la altura del agua. Terminada la recuperación, gira los pies hacia fuera y empuja hacia atrás hasta juntar talones y pies, con las puntas de los pies estiradas hacia atrás. Un pull buoy puede ayudar a mantener las rodillas en posición neutra.",
 "Sacar las rodillas del agua o abrir las costillas."),
"rana-due-gambate-una-bracciata": ("Braza: dos patadas, una brazada",
 "Cuidar la posición alargada y la respiración reduciendo el número de brazadas.",
 "Nada braza haciendo dos patadas por cada brazada. Tras la respiración, vuelve a poner enseguida la cabeza en línea con el cuerpo. Impúlsate hacia delante justo bajo la superficie, sin bajar a profundidad, y usa la segunda patada para avanzar como una flecha.",
 "Mantener la cabeza alta después de respirar o sumergirse demasiado."),
"rana-corpo-verso-le-mani": ("Braza: el cuerpo hacia las manos",
 "Entender que en la brazada de braza es el cuerpo el que avanza hacia las manos.",
 "Empieza en posición alargada. En cuanto las manos se abren, sujeta el agua con las palmas, normalmente más allá del ancho de los hombros, y gira las manos hacia atrás. Lleva el cuerpo hacia delante, hacia las manos, y vuelve a la posición alargada tras cada brazada completa. Se puede hacer con un pull buoy.",
 "Tirar de las manos hacia el cuerpo en lugar de llevar el cuerpo hacia las manos."),
"delfino-un-braccio-alla-volta": ("Mariposa a un brazo",
 "Cuidar la brazada de mariposa un brazo cada vez, manteniendo la ondulación.",
 "Un brazo se queda estirado hacia delante y estabiliza el cuerpo, mientras el otro hace la brazada y la recuperación cerca de la superficie, estirado pero relajado. Respira hacia delante solo en las brazadas completas con los dos brazos. Alterna los lados.",
 "Dejar que el cuerpo gire: el brazo de delante sirve para mantenerlo estable."),
}

# ---------------------------------------------------------------- errori
# id -> (nome, come_si_riconosce, perche, correzione)
ERRORI = {"en": {}, "es": {}}
ERRORI["en"] = {
"testa-alta": ("Head held high",
 "You look ahead and your legs tend to sink.",
 "Your legs sink and drag increases.",
 "Look at the bottom with your head in line with your body, as if it were a single pencil."),
"respiro-trattenuto": ("Held breath",
 "You hold air in underwater and then gasp when breathing in.",
 "Breathing in becomes long and laboured.",
 "Breathe out continuously in the water and breathe in quickly by turning your head."),
"gambe-che-pedalano": ("Pedalling legs",
 "Your knees bend a lot.",
 "You spend energy without moving forward.",
 "Start the kick from the hip, with little knee bend and your feet close to the surface."),
"braccia-incrociate": ("Arms crossing in front",
 "Your hand enters the water beyond the centre line of your body.",
 "It reduces efficiency and can tire the shoulder.",
 "Enter with your hand in front of your shoulder, without going past the line of your body."),
"braccia-a-mulino": ("Windmill arms",
 "Your arms move in opposition and the pull starts too early.",
 "The rhythm of the stroke and of breathing breaks down.",
 "Keep one arm stretched out in front until the other one reaches it."),
"testa-alzata-per-respirare": ("Head lifted to breathe",
 "To breathe you lift your head instead of turning it.",
 "Your legs sink and drag increases.",
 "Turn your head, shoulders and hips together, without overdoing it."),
"recupero-anticipato": ("Recovery that starts too early",
 "The arm leaves the water before finishing the push.",
 "You lose power in the last part of the stroke.",
 "Bring your hand all the way to your thigh and count your strokes per length, trying to reduce them."),
"partenza-troppo-forte": ("Starting too hard",
 "The first lengths are fast and then you have to stop.",
 "The workout gets interrupted.",
 "Start slowly, at a pace that lets you talk between lengths."),
"collo-e-spalle-rigidi": ("Stiff neck and shoulders",
 "Your shoulders are high and your neck is tense.",
 "Stiffness makes you sink and tires you sooner.",
 "Relax your shoulders and let the water support you."),
"niente-riscaldamento-e-recupero": ("No warm-up and cool-down",
 "You start and finish abruptly, without easy lengths.",
 "You start cold and finish without letting your pace come down.",
 "Always start and finish with a few easy lengths."),
"dorso-testa-troppo-indietro": ("Head too far back in backstroke",
 "Your chin points up and your ribs open.",
 "You lose the connection with the centre of your body and your position weakens.",
 "Keep your head in line with your body, look up and a little towards your feet, and keep your ribs down."),
"dorso-spalla-al-mento": ("Shoulder rising towards the chin in backstroke",
 "During the rotation a shoulder comes out of the water and rises towards your chin.",
 "The rotation starts from the shoulder instead of the hips and you lose your head and body position.",
 "Rotate from the hips, keep your shoulders low and hold your head and body position steady."),
"rana-piedi-non-ruotati": ("Feet not turned out in breaststroke",
 "In the kick your feet stay in line with your legs, without turning outwards.",
 "Without turned-out, flexed feet the push backwards is weak.",
 "Bring your heels towards your buttocks, turn your feet out and flex them, then push back in a circular motion until your legs are straight and together."),
"rana-mani-verso-il-corpo": ("Hands pulled towards the body in breaststroke",
 "In the pull your hands are brought towards your body and the grip on the water is poor.",
 "You do not use the grip on the water to move forward.",
 "After the sweep out, hold the water with your palms and bring your body forward towards your hands, then return to the stretched-out position."),
"rana-senza-scivolo": ("No return to the stretched-out position in breaststroke",
 "After the pull you start again straight away, without bringing your body back to a stretched-out position.",
 "You lose the forward movement the kick gave you.",
 "After each complete pull return to the arrow position and stay stretched out while you glide, counting in your head."),
"rana-testa-alta-dopo-il-respiro": ("Head up after the breath in breaststroke",
 "After breathing your head stays out and your body does not return to line.",
 "Your body is not stretched out just when it should be gliding.",
 "Bring your head back in line with your body as soon as possible and glide just below the surface, without going deep."),
"delfino-solo-gambe": ("Butterfly with the legs only",
 "Your legs kick but the undulation does not start from the chest.",
 "The movement loses its fluidity and the body does not work as a single wave.",
 "Press your chest down and let the movement travel down to your feet: the kick starts from the chest."),
"delfino-piede-fuori-dall-acqua": ("Whole foot coming out of the water in butterfly",
 "In the kick the whole foot comes out of the water.",
 "The kick loses its shape and its timing with the arms.",
 "Let only your heels and the tips of your feet break the surface, and take care over the two moments of push: hands exiting and entering."),
"delfino-spalle-alte": ("Shoulders up towards the head in butterfly",
 "When the hands start the pull your shoulders rise towards your ears.",
 "Your elbow does not stay high and the pull gets weaker.",
 "Keep your shoulders low while keeping your elbows high."),
}
ERRORI["es"] = {
"testa-alta": ("Cabeza levantada",
 "Se mira hacia delante y las piernas tienden a hundirse.",
 "Las piernas se hunden y aumenta la resistencia.",
 "Mira al fondo con la cabeza en línea con el cuerpo, como si fuera un único lápiz."),
"respiro-trattenuto": ("Respiración contenida",
 "Se aguanta el aire bajo el agua y se inspira con ahogo.",
 "La inspiración se vuelve larga y entrecortada.",
 "Espira de forma continua en el agua e inspira en un instante girando la cabeza."),
"gambe-che-pedalano": ("Piernas que pedalean",
 "Las rodillas se doblan mucho.",
 "Se gasta energía sin avanzar.",
 "Haz que la patada parta de la cadera, con poca flexión de las rodillas y los pies cerca de la superficie."),
"braccia-incrociate": ("Brazos que se cruzan por delante",
 "La mano entra en el agua más allá del centro del cuerpo.",
 "Reduce la eficiencia y puede cansar el hombro.",
 "Haz entrar la mano delante del hombro, sin pasar la línea del cuerpo."),
"braccia-a-mulino": ("Brazos de molino",
 "Los brazos se mueven en oposición y la tracción empieza demasiado pronto.",
 "Se rompe el ritmo de la brazada y de la respiración.",
 "Mantén un brazo estirado delante hasta que el otro lo alcance."),
"testa-alzata-per-respirare": ("Cabeza levantada para respirar",
 "Para respirar se levanta la cabeza en lugar de girarla.",
 "Las piernas se hunden y aumenta la resistencia.",
 "Gira la cabeza, los hombros y las caderas a la vez, sin exagerar."),
"recupero-anticipato": ("Recuperación demasiado anticipada",
 "El brazo sale del agua antes de terminar el empuje.",
 "Se pierde potencia en la parte final de la brazada.",
 "Lleva la mano hasta el muslo y cuenta las brazadas por largo, intentando reducirlas."),
"partenza-troppo-forte": ("Salida demasiado fuerte",
 "Los primeros largos son rápidos y después hay que parar.",
 "El entrenamiento se interrumpe.",
 "Empieza despacio, a un ritmo que te permita hablar entre un largo y otro."),
"collo-e-spalle-rigidi": ("Cuello y hombros rígidos",
 "Los hombros están altos y el cuello tenso.",
 "La rigidez hace que te hundas y te cansa antes.",
 "Relaja los hombros y deja que el agua te sostenga."),
"niente-riscaldamento-e-recupero": ("Sin calentamiento ni vuelta a la calma",
 "Se empieza y se termina de golpe, sin largos fáciles.",
 "Se empieza en frío y se termina sin bajar el ritmo.",
 "Empieza y termina siempre con unos cuantos largos fáciles."),
"dorso-testa-troppo-indietro": ("Cabeza demasiado atrás en la espalda",
 "La barbilla apunta hacia arriba y las costillas se abren.",
 "Se pierde la conexión con el centro del cuerpo y la posición se debilita.",
 "Mantén la cabeza en línea con el cuerpo, mira hacia arriba y un poco hacia los pies, y mantén las costillas bajas."),
"dorso-spalla-al-mento": ("Hombro que sube hacia la barbilla en la espalda",
 "Durante la rotación un hombro sale del agua y sube hacia la barbilla.",
 "La rotación parte del hombro en lugar de las caderas y se pierde la posición de la cabeza y del cuerpo.",
 "Gira desde las caderas, mantén los hombros bajos y la posición de la cabeza y del cuerpo estable."),
"rana-piedi-non-ruotati": ("Pies sin girar hacia fuera en la braza",
 "En la patada los pies se quedan en línea con las piernas, sin girar hacia fuera.",
 "Sin los pies girados y flexionados, el empuje hacia atrás es débil.",
 "Lleva los talones hacia los glúteos, gira los pies hacia fuera y flexiónalos; después empuja hacia atrás en un movimiento circular hasta tener las piernas estiradas y juntas."),
"rana-mani-verso-il-corpo": ("Manos que tiran hacia el cuerpo en la braza",
 "En la brazada las manos se llevan hacia el cuerpo y el agarre del agua es escaso.",
 "No se aprovecha el agarre del agua para avanzar.",
 "Tras la apertura, sujeta el agua con las palmas y lleva el cuerpo hacia delante, hacia las manos; después vuelve a la posición alargada."),
"rana-senza-scivolo": ("Braza sin volver a la posición alargada",
 "Tras la brazada se vuelve a empezar enseguida, sin llevar el cuerpo a la posición alargada.",
 "Se pierde el avance que dio la patada.",
 "Tras cada brazada completa vuelve a la posición de flecha y quédate alargado mientras te deslizas, contando mentalmente."),
"rana-testa-alta-dopo-il-respiro": ("Cabeza alta tras la respiración en la braza",
 "Después de respirar la cabeza se queda fuera y el cuerpo no vuelve a la línea.",
 "El cuerpo no está alargado justo cuando debería deslizarse.",
 "Vuelve a poner la cabeza en línea con el cuerpo lo antes posible y deslízate justo bajo la superficie, sin bajar a profundidad."),
"delfino-solo-gambe": ("Mariposa solo con las piernas",
 "Las piernas baten pero la ondulación no parte del pecho.",
 "El movimiento pierde fluidez y el cuerpo no trabaja como una única onda.",
 "Presiona el pecho hacia abajo y deja que el movimiento baje hasta los pies: la patada nace del pecho."),
"delfino-piede-fuori-dall-acqua": ("Pie que sale entero del agua en la mariposa",
 "En la patada sale del agua todo el pie.",
 "La patada pierde su forma y su ritmo con los brazos.",
 "Deja que afloren solo los talones y la punta de los pies, y cuida los dos momentos de empuje: salida y entrada de las manos."),
"delfino-spalle-alte": ("Hombros hacia la cabeza en la mariposa",
 "Cuando las manos empiezan la tracción, los hombros suben hacia las orejas.",
 "El codo no se mantiene alto y la tracción se debilita.",
 "Mantén los hombros bajos manteniendo los codos altos."),
}

# ---------------------------------------------------------------- tappe
# id -> (nome, obiettivo, test)
TAPPE = {"en": {}, "es": {}}
TAPPE["en"] = {
1: ("Confidence in the water and floating", "Be calm in the water and feel supported.",
    "You float face down for 10 seconds and on your back for 15 seconds, in water where you can touch the bottom, and stand up on your own."),
2: ("Breathing", "Breathe out in the water and breathe in by turning your head.",
    "You blow bubbles at least 3 times with your nose and mouth underwater and take 5 rhythmic breaths turning your head, without swallowing water."),
3: ("Body position and gliding", "Have a long body that glides.",
    "After pushing off the wall you glide face down and on your back staying aligned, with your head between your arms."),
4: ("Leg kick", "A continuous kick that starts from the hip.",
    "You cover 10 metres of freestyle kick, with or without a kickboard."),
5: ("Freestyle stroke", "A long, coordinated stroke.",
    "You swim 25 metres of freestyle without stopping, even with simplified breathing."),
6: ("Coordination and side breathing", "Breathe to the side with rhythm without losing your position.",
    "You swim 50 metres of freestyle breathing with rhythm, without stopping."),
7: ("Swimming continuously", "Build a base of endurance at an easy pace.",
    "You swim 100 metres of freestyle without stopping, at an easy pace."),
8: ("Backstroke", "Swim backstroke with a coordinated kick and pull.",
    "You swim 25 metres of backstroke with a coordinated kick and pull."),
9: ("Breaststroke", "Coordinate pull, kick and glide.",
    "You swim 25 metres of breaststroke with a glide after every cycle."),
10: ("Butterfly", "Learn the undulation and its coordination.",
    "You swim 25 metres of butterfly with the undulation led by the chest."),
}
TAPPE["es"] = {
1: ("Confianza en el agua y flotación", "Estar en el agua con tranquilidad y sentirse sostenido.",
    "Flotas boca abajo durante 10 segundos y boca arriba durante 15 segundos, en agua donde hagas pie, y te levantas solo."),
2: ("Respiración", "Espirar en el agua e inspirar girando la cabeza.",
    "Soplas burbujas al menos 3 veces con la nariz y la boca bajo el agua y haces 5 respiraciones rítmicas girando la cabeza, sin tragar agua."),
3: ("Posición del cuerpo y deslizamiento", "Tener un cuerpo alargado que se deslice.",
    "Tras el impulso desde el borde te deslizas boca abajo y boca arriba manteniéndote alineado, con la cabeza entre los brazos."),
4: ("Patada", "Una patada continua que parte de la cadera.",
    "Recorres 10 metros de patada de crol, con o sin tabla."),
5: ("Brazada de crol", "Una brazada larga y coordinada.",
    "Nadas 25 metros de crol sin parar, incluso con una respiración simplificada."),
6: ("Coordinación y respiración lateral", "Respirar de lado con ritmo sin perder la posición.",
    "Nadas 50 metros de crol respirando con ritmo, sin parar."),
7: ("Nadar con continuidad", "Construir una resistencia de base con un ritmo fácil.",
    "Nadas 100 metros de crol sin parar, con un ritmo fácil."),
8: ("Espalda", "Nadar espalda con patada y brazada coordinadas.",
    "Nadas 25 metros de espalda con patada y brazada coordinadas."),
9: ("Braza", "Coordinar brazada, patada y deslizamiento.",
    "Nadas 25 metros de braza con deslizamiento después de cada ciclo."),
10: ("Mariposa", "Aprender la ondulación y su coordinación.",
    "Nadas 25 metros de mariposa con la ondulación guiada por el pecho."),
}

# ---------------------------------------------------------------- zone
ZONE = {"en": {}, "es": {}}
ZONE["en"] = {
"facile": ("Easy", "A comfortable pace, where you can still breathe calmly and think about your technique. Good for warming up, recovering and whenever you want to swim without effort."),
"regolare": ("Steady", "A constant pace that you feel but can hold for a long time. It is the zone for building endurance, length after length."),
"sostenuto": ("Brisk", "A demanding but controlled pace, just below your reference pace. You feel the effort, but you know you can make it to the end of the set."),
"ritmo-critico": ("Hard", "A tough pace, a little slower than your all-out 200 m. It is used in short sets with short rests, not for swimming a long time in one go."),
"veloce": ("Fast", "The pace of your all-out 200 m, or close to it. For short stretches, with a real rest after each one: only the most experienced use it."),
}
ZONE["es"] = {
"facile": ("Fácil", "Un ritmo cómodo, con el que puedes respirar con tranquilidad y pensar en la técnica. Va bien para calentar, para recuperar y para cuando quieres nadar sin esfuerzo."),
"regolare": ("Regular", "Un ritmo constante que notas pero que puedes mantener mucho tiempo. Es la zona para construir resistencia, largo tras largo."),
"sostenuto": ("Sostenido", "Un ritmo exigente pero controlado, justo por debajo de tu ritmo de referencia. Se nota el esfuerzo, pero sabes que puedes llegar al final de la serie."),
"ritmo-critico": ("Exigente", "Un ritmo duro, un poco por debajo del de tus 200 m a tope. Se usa en series cortas con pausas breves, no para nadar mucho rato seguido."),
"veloce": ("Rápido", "El ritmo de tus 200 m a tope o casi. Para tramos cortos, con una pausa de verdad después de cada tramo: solo lo usan los más expertos."),
}

ISTRUZIONI = {
"en": "The test is used to find your reference pace. Before the test: only do it if you feel well and are used to swimming continuously (it is recommended from the intermediate level up). An all-out effort is tiring: if in doubt, ask your doctor. How to do it: 1) Warm up with 200-400 m easy, plus a few short pick-ups. 2) Swim 200 m of freestyle all-out, that is, at the fastest pace you can hold until the end, starting from the wall (no dive). Spread your effort wisely: do not start too fast. 3) Note your time and enter it in the app. If the time seems too far from what you usually do, repeat the test another day. If you feel unwell, stop and rest.",
"es": "La prueba sirve para encontrar tu ritmo de referencia. Antes de la prueba: hazla solo si te encuentras bien y estás acostumbrado a nadar con continuidad (se recomienda a partir del nivel intermedio). Un esfuerzo a tope cansa: en caso de duda, consulta con tu médico. Cómo se hace: 1) Calienta con 200-400 m fáciles, más algunos cambios de ritmo cortos. 2) Nada 200 m de crol a tope, es decir, al ritmo más rápido que puedas mantener hasta el final, saliendo desde el borde (sin salto). Reparte el esfuerzo con inteligencia: no salgas demasiado fuerte. 3) Anota el tiempo e introdúcelo en la app. Si el tiempo te parece demasiado lejano de lo que haces normalmente, repite la prueba otro día. Si te encuentras mal, para y descansa.",
}

# ---------------------------------------------------------------- titoli degli allenamenti
CATEGORIE = {
 "Tecnica": ("Technique", "Técnica"),
 "Fondo facile": ("Easy endurance", "Fondo suave"),
 "Fondo": ("Endurance", "Fondo"),
 "Ritmo alto": ("Fast pace", "Ritmo alto"),
 "Soglia": ("Threshold", "Umbral"),
 "Tolleranza": ("Tolerance", "Tolerancia"),
}
FISSI = {
 "Bracciata lunga": ("Long stroke", "Brazada larga"),
 "Continuità con il pull buoy": ("Steady swimming with the pull buoy", "Continuidad con el pull buoy"),
 "Fondo": ("Endurance", "Fondo"),
 "Fondo facile": ("Easy endurance", "Fondo suave"),
 "Costanza in vasca": ("Consistency in the pool", "Constancia en la piscina"),
 "Costruire resistenza": ("Building endurance", "Construir resistencia"),
 "Delfino: l'onda dal petto": ("Butterfly: the wave from the chest", "Mariposa: la onda desde el pecho"),
 "Dorso e rana": ("Backstroke and breaststroke", "Espalda y braza"),
 "Dorso e stile libero": ("Backstroke and freestyle", "Espalda y crol"),
 "Prime vasche tranquille": ("Easy first lengths", "Primeros largos tranquilos"),
 "Rana con scivolo": ("Breaststroke with glide", "Braza con deslizamiento"),
 "Rana: due gambate, una bracciata": ("Breaststroke: two kicks, one pull", "Braza: dos patadas, una brazada"),
 "Resistenza con pull buoy": ("Endurance with the pull buoy", "Resistencia con pull buoy"),
 "Resistenza intermedia": ("Intermediate endurance", "Resistencia intermedia"),
 "Respirare di lato": ("Breathing to the side", "Respirar de lado"),
 "Respiro e scivolo": ("Breath and glide", "Respiración y deslizamiento"),
 "Tecnica e ritmo": ("Technique and pace", "Técnica y ritmo"),
 "Ritmo alto: cento veloci": ("Fast pace: fast hundreds", "Ritmo alto: cienes rápidos"),
 "Soglia: serie lunghe": ("Threshold: long sets", "Umbral: series largas"),
 "Tolleranza: cinquanta e cento": ("Tolerance: fifties and hundreds", "Tolerancia: cincuentas y cienes"),
 "Tolleranza: forte con recupero lungo": ("Tolerance: hard with long rest", "Tolerancia: fuerte con descanso largo"),
}
SERIE_DA = {  # "Ritmo alto: serie da N" / "Soglia: ripetute da N"
 "Ritmo alto: serie da": ("Fast pace: {n} m sets", "Ritmo alto: series de {n} m"),
 "Soglia: ripetute da": ("Threshold: {n} m repeats", "Umbral: repeticiones de {n} m"),
}
CONGIUNZIONE = {"en": " and ", "es": " y "}


def minuscola(testo):
    return testo[0].lower() + testo[1:]


def nomi_drill(lingua):
    """Italiano minuscolo -> nome tradotto minuscolo, per i titoli 'Tecnica: ...'."""
    it = {d["id"]: d["nome"] for d in json.load(open(os.path.join(CONTENT, "drills.json"), encoding="utf-8"))["drill"]}
    return {minuscola(it[k]): minuscola(v[0]) for k, v in DRILL[lingua].items()}


def traduci_titolo(titolo, lingua, drill_nomi):
    i = 0 if lingua == "en" else 1
    if titolo in FISSI:
        return FISSI[titolo][i]
    for prefisso, modello in SERIE_DA.items():
        m = re.fullmatch(re.escape(prefisso) + r" (\d+)", titolo)
        if m:
            return modello[i].format(n=m.group(1))
    prefisso, _, resto = titolo.partition(": ")
    if prefisso not in CATEGORIE or not resto:
        raise ValueError(f"titolo non riconosciuto: {titolo!r}")
    cat = CATEGORIE[prefisso][i]
    # coda " · 550 m" e " · variante 2"
    parti = resto.split(" · ")
    corpo, code = parti[0], parti[1:]
    code_tradotte = []
    for c in code:
        m = re.fullmatch(r"variante (\d+)", c)
        code_tradotte.append((f"variant {m.group(1)}" if lingua == "en" else f"variante {m.group(1)}") if m else c)
    if prefisso == "Tecnica":
        # elenco di drill separati da " e " (alcuni nomi contengono già " e ": si cerca la scomposizione che li riconosce tutti)
        def scomponi(s):
            if s in drill_nomi:
                return [drill_nomi[s]]
            for k in sorted(drill_nomi, key=len, reverse=True):
                for sep in (" e ",):
                    if s.startswith(k + sep):
                        r = scomponi(s[len(k) + len(sep):])
                        if r:
                            return [drill_nomi[k]] + r
            return None
        elenco = scomponi(corpo)
        if elenco is None:
            raise ValueError(f"drill non riconosciuti nel titolo: {titolo!r}")
        corpo_t = CONGIUNZIONE[lingua].join(elenco)
    else:
        corpo_t = corpo  # "6 × 50 m + 4 × 25 m": numeri e simboli uguali in tutte le lingue
    return " · ".join([f"{cat}: {corpo_t}"] + code_tradotte)


def titoli_italiani():
    titoli = set()
    for f in glob.glob(os.path.join(CONTENT, "allenamenti", "*.json")):
        if f.endswith("indice.json"):
            continue
        titoli.add(json.load(open(f, encoding="utf-8"))["titolo"])
    return sorted(titoli)


def costruisci(lingua):
    drill_nomi = nomi_drill(lingua)
    return {
        "nota": "Traduzioni dei contenuti tecnici (originali in italiano nei file di content/). Generato da tools/genera_traduzioni.py: non modificare a mano.",
        "tappe": {str(k): {"nome": v[0], "obiettivo": v[1], "test": v[2]} for k, v in TAPPE[lingua].items()},
        "drill": {k: {"nome": v[0], "scopo": v[1], "esecuzione": v[2], "errore_da_evitare": v[3]} for k, v in DRILL[lingua].items()},
        "errori": {k: {"nome": v[0], "come_si_riconosce": v[1], "perche_e_un_problema": v[2], "correzione": v[3]} for k, v in ERRORI[lingua].items()},
        "zone": {k: {"nome": v[0], "descrizione": v[1]} for k, v in ZONE[lingua].items()},
        "istruzioni_test": ISTRUZIONI[lingua],
        "titoli": {t: traduci_titolo(t, lingua, drill_nomi) for t in titoli_italiani()},
    }


def controlla():
    """Ogni contenuto approvato deve avere la traduzione in tutte le lingue."""
    mancanti = []
    def ids(file, chiave):
        return [x["id"] for x in json.load(open(os.path.join(CONTENT, file), encoding="utf-8"))[chiave] if x.get("stato") == "approvato"]
    for lingua in ("en", "es"):
        for k in ids("drills.json", "drill"):
            if k not in DRILL[lingua]: mancanti.append(f"{lingua} drill {k}")
        for k in ids("errori-comuni.json", "errori"):
            if k not in ERRORI[lingua]: mancanti.append(f"{lingua} errore {k}")
        for k in ids("percorso.json", "tappe"):
            if k not in TAPPE[lingua]: mancanti.append(f"{lingua} tappa {k}")
        for k in ids("zone-ritmo.json", "zone"):
            if k not in ZONE[lingua]: mancanti.append(f"{lingua} zona {k}")
    if mancanti:
        raise SystemExit("Traduzioni mancanti:\n" + "\n".join(mancanti))


if __name__ == "__main__":
    controlla()
    os.makedirs(os.path.join(CONTENT, "i18n"), exist_ok=True)
    for lingua in ("en", "es"):
        percorso = os.path.join(CONTENT, "i18n", f"{lingua}.json")
        with open(percorso, "w", encoding="utf-8") as f:
            json.dump(costruisci(lingua), f, ensure_ascii=False, indent=2)
            f.write("\n")
        print("scritto", os.path.relpath(percorso, RADICE))
