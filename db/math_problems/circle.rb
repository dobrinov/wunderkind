def seed_circle_question(script, answer, numbers)
  question = Question.create!(text: 'Кое е числото в жълтото квадратче?', answer:)

  question.question_attachment =
    QuestionAttachment.create! question:,
                               attachable: script,
                               attachable_parameters: { firstFive: numbers }
end

def seed_circle_questions
  script = ScriptAttachment.create! code: <<~JAVASCRIPT
    // Configuration constants
    const CONFIG = {
      PADDING_PERCENTAGE: 0.2,
      SQUARE_SIZE_PERCENTAGE: 0.2,
      EXTRA_DISTANCE_PERCENTAGE: 0.2,
      LINE_WIDTH_PERCENTAGE: 0.02,
      SPACE_FROM_CIRCLE_PERCENTAGE: 0.05,
      CONTROL_POINT_DISTANCE_PERCENTAGE: 0.6,
      ARROW_LENGTH_PERCENTAGE: 0.075,
      SQUARE_DISTANCE_PERCENTAGE: 0.3,
      SQUARE_SIZE_PERCENTAGE: 0.3,
      FONT_SIZE_PERCENTAGE: 0.5,
      TEXT_DISTANCE_PERCENTAGE: 0.7,
      NUMBER_OF_POINTS: 6,
      DEGREES_PER_POINT: 60,
      START_ANGLE_OFFSET: 35,
      END_ANGLE_OFFSET: 85
    };

    class Diagram {
      constructor(canvas) {
        this.canvas = canvas;
        this.ctx = canvas.getContext('2d');
        this.centerX = canvas.width / 2;
        this.centerY = canvas.height / 2;
        this.radius = Math.min(canvas.width, canvas.height) / 2 -
                    (Math.min(canvas.width, canvas.height) * CONFIG.PADDING_PERCENTAGE);
      }

      drawCircle() {
        this.ctx.beginPath();
        this.ctx.arc(this.centerX, this.centerY, this.radius, 0, Math.PI * 2);
        this.ctx.fillStyle = 'white';
        this.ctx.fill();
        this.ctx.stroke();
      }

      drawCurvedLines() {
        for (let i = 0; i < CONFIG.NUMBER_OF_POINTS; i++) {
          const angle1 = ((i * CONFIG.DEGREES_PER_POINT) + CONFIG.START_ANGLE_OFFSET) * Math.PI / 180;
          const angle2 = ((i * CONFIG.DEGREES_PER_POINT) + CONFIG.END_ANGLE_OFFSET) * Math.PI / 180;

          const spaceFromCircle = this.radius * CONFIG.SPACE_FROM_CIRCLE_PERCENTAGE;
          const x1 = this.centerX + (this.radius + spaceFromCircle) * Math.cos(angle1);
          const y1 = this.centerY + (this.radius + spaceFromCircle) * Math.sin(angle1);
          const x2 = this.centerX + (this.radius + spaceFromCircle) * Math.cos(angle2);
          const y2 = this.centerY + (this.radius + spaceFromCircle) * Math.sin(angle2);

          const controlAngle = (angle1 + angle2) / 2;
          const controlDistance = this.radius + (this.radius * CONFIG.CONTROL_POINT_DISTANCE_PERCENTAGE);
          const controlX = this.centerX + controlDistance * Math.cos(controlAngle);
          const controlY = this.centerY + controlDistance * Math.sin(controlAngle);

          this.drawCurvedLine(x1, y1, x2, y2, controlX, controlY);
          this.drawArrow(x2, y2, controlX, controlY);
        }
      }

      drawCurvedLine(x1, y1, x2, y2, controlX, controlY) {
        this.ctx.beginPath();
        this.ctx.moveTo(x1, y1);
        this.ctx.quadraticCurveTo(controlX, controlY, x2, y2);
        this.ctx.strokeStyle = 'black';
        this.ctx.stroke();
      }

      drawArrow(x, y, controlX, controlY) {
        const arrowLength = this.radius * CONFIG.ARROW_LENGTH_PERCENTAGE;
        const arrowAngle = Math.atan2(y - controlY, x - controlX);

        this.ctx.beginPath();
        this.ctx.moveTo(x, y);
        this.ctx.lineTo(
          x - arrowLength * Math.cos(arrowAngle - Math.PI/6),
          y - arrowLength * Math.sin(arrowAngle - Math.PI/6)
        );
        this.ctx.moveTo(x, y);
        this.ctx.lineTo(
          x - arrowLength * Math.cos(arrowAngle + Math.PI/6),
          y - arrowLength * Math.sin(arrowAngle + Math.PI/6)
        );
        this.ctx.stroke();
      }

      drawDiameterLines() {
        for (let i = 0; i < 3; i++) {
          const angle = (i * Math.PI) / 3;
          const x1 = this.centerX + this.radius * Math.cos(angle);
          const y1 = this.centerY + this.radius * Math.sin(angle);
          const x2 = this.centerX - this.radius * Math.cos(angle);
          const y2 = this.centerY - this.radius * Math.sin(angle);

          this.ctx.beginPath();
          this.ctx.moveTo(x1, y1);
          this.ctx.lineTo(x2, y2);
          this.ctx.stroke();
        }
      }

      drawSquares(numbers) {
        for (let i = 0; i < CONFIG.NUMBER_OF_POINTS; i++) {
          const angle = (i * Math.PI) / 3;
          const distance = this.radius + (this.radius * CONFIG.SQUARE_DISTANCE_PERCENTAGE);
          const squareSize = this.radius * CONFIG.SQUARE_SIZE_PERCENTAGE;
          const x = this.centerX + distance * Math.cos(angle);
          const y = this.centerY + distance * Math.sin(angle);

          const prevIndex = (i + 5) % CONFIG.NUMBER_OF_POINTS;
          const squareValue = numbers[i] - numbers[prevIndex];

          this.drawSquare(x, y, squareSize, squareValue, i === 0);
        }
      }

      drawSquare(x, y, size, value, isFirst) {
        this.ctx.beginPath();
        this.ctx.rect(x - size / 2, y - size / 2, size, size);
        if(isFirst) {
          this.ctx.fillStyle = 'yellow';
        } else {
          this.ctx.fillStyle = 'white';
        }
        this.ctx.fill();
        this.ctx.stroke();

        const fontSize = size * CONFIG.FONT_SIZE_PERCENTAGE;
        this.ctx.font = `${fontSize}px Arial`;
        this.ctx.textAlign = 'center';
        this.ctx.textBaseline = 'middle';
        this.ctx.fillStyle = 'black';
        this.ctx.fillText(isFirst ? '?' : (value >= 0 ? '+' : '') + value.toString(), x, y);
      }

      drawNumbers(numbers) {
        this.ctx.font = `${this.radius * 0.20}px Arial`;
        this.ctx.textAlign = 'center';
        this.ctx.textBaseline = 'middle';
        this.ctx.fillStyle = 'black';

        for (let i = 0; i < CONFIG.NUMBER_OF_POINTS; i++) {
          const angle = (i * Math.PI) / 3 + Math.PI / 6;
          const textDistance = this.radius * CONFIG.TEXT_DISTANCE_PERCENTAGE;
          const x = this.centerX + textDistance * Math.cos(angle);
          const y = this.centerY + textDistance * Math.sin(angle);

          this.ctx.fillText(i === 0 ? numbers[i].toString() : '?', x, y);
        }
      }

      draw(numbers) {
        if (!Array.isArray(numbers) || numbers.length !== CONFIG.NUMBER_OF_POINTS) {
          throw new Error(`Must provide exactly ${CONFIG.NUMBER_OF_POINTS} numbers`);
        }

        this.ctx.lineWidth = Math.max(1, this.radius * CONFIG.LINE_WIDTH_PERCENTAGE);

        this.drawCircle();
        this.drawCurvedLines();
        this.drawDiameterLines();
        this.drawSquares(numbers);
        this.drawNumbers(numbers);
      }
    }

    function execute({answer, params: { firstFive }}) {
      const canvas = document.querySelector('canvas');
      const parentWidth = canvas.parentElement.clientWidth;
      canvas.width = parentWidth;
      canvas.height = parentWidth;
      const diagram = new Diagram(canvas);
      const numbers = firstFive.map(x => parseInt(x));
      diagram.draw([...numbers, numbers[0] - parseInt(answer)]);
    }
  JAVASCRIPT

  seed_circle_question script, 5, [ 5, 8, 3, 4, 6 ]
  seed_circle_question script, 6, [ 1, 9, 3, 4, 8 ]
  seed_circle_question script, 2, [ 4, 2, 9, 1, 3 ]
  seed_circle_question script, 10, [ 4, 12, 19, 7, 20 ]
end
