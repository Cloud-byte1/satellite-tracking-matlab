"""Build the paginated final engineering report from verified project outputs."""

from pathlib import Path

from reportlab.lib import colors
from reportlab.lib.enums import TA_CENTER, TA_LEFT
from reportlab.lib.pagesizes import letter
from reportlab.lib.styles import ParagraphStyle, getSampleStyleSheet
from reportlab.lib.units import inch
from reportlab.platypus import (
    Image,
    PageBreak,
    Paragraph,
    SimpleDocTemplate,
    Spacer,
    Table,
    TableStyle,
)


ROOT = Path(__file__).resolve().parents[1]
OUTPUT = ROOT / "output" / "pdf" / "satellite_tracking_final_engineering_report.pdf"
FIGURES = ROOT / "figures"

NAVY = colors.HexColor("#17324D")
BLUE = colors.HexColor("#176B87")
TEAL = colors.HexColor("#2A9D8F")
LIGHT = colors.HexColor("#EAF1F5")
MID = colors.HexColor("#D5E2EA")
DARK = colors.HexColor("#1F2933")


def paragraph(text, style):
    return Paragraph(text, style)


def page_header_footer(canvas, doc):
    canvas.saveState()
    width, height = letter
    if doc.page > 1:
        canvas.setFillColor(NAVY)
        canvas.rect(0, height - 0.38 * inch, width, 0.38 * inch, fill=1, stroke=0)
        canvas.setFillColor(colors.white)
        canvas.setFont("Helvetica-Bold", 8.5)
        canvas.drawString(0.65 * inch, height - 0.25 * inch,
                          "SATELLITE TRACKING ENGINEERING REPORT")
    canvas.setStrokeColor(MID)
    canvas.line(0.65 * inch, 0.47 * inch, width - 0.65 * inch, 0.47 * inch)
    canvas.setFillColor(colors.HexColor("#52616B"))
    canvas.setFont("Helvetica", 8)
    canvas.drawString(0.65 * inch, 0.29 * inch, "MATLAB R2026b acceptance run - 21 October 2026")
    canvas.drawRightString(width - 0.65 * inch, 0.29 * inch, f"Page {doc.page}")
    canvas.restoreState()


def metric_table(rows, widths=(3.9 * inch, 2.3 * inch)):
    table = Table(rows, colWidths=list(widths), repeatRows=1)
    table.setStyle(TableStyle([
        ("BACKGROUND", (0, 0), (-1, 0), NAVY),
        ("TEXTCOLOR", (0, 0), (-1, 0), colors.white),
        ("FONTNAME", (0, 0), (-1, 0), "Helvetica-Bold"),
        ("FONTNAME", (0, 1), (-1, -1), "Helvetica"),
        ("FONTSIZE", (0, 0), (-1, -1), 8.7),
        ("ROWBACKGROUNDS", (0, 1), (-1, -1), [colors.white, LIGHT]),
        ("GRID", (0, 0), (-1, -1), 0.35, colors.HexColor("#AABCC7")),
        ("VALIGN", (0, 0), (-1, -1), "MIDDLE"),
        ("LEFTPADDING", (0, 0), (-1, -1), 6),
        ("RIGHTPADDING", (0, 0), (-1, -1), 6),
        ("TOPPADDING", (0, 0), (-1, -1), 5),
        ("BOTTOMPADDING", (0, 0), (-1, -1), 5),
    ]))
    return table


def report_image(filename, width, height):
    image = Image(str(FIGURES / filename), width=width, height=height)
    image.hAlign = "CENTER"
    return image


def build_report():
    OUTPUT.parent.mkdir(parents=True, exist_ok=True)
    styles = getSampleStyleSheet()
    body = ParagraphStyle(
        "Body", parent=styles["BodyText"], fontName="Helvetica", fontSize=9.1,
        leading=12.0, textColor=DARK, spaceAfter=6, alignment=TA_LEFT,
    )
    small = ParagraphStyle(
        "Small", parent=body, fontSize=7.7, leading=9.8, spaceAfter=3,
    )
    h1 = ParagraphStyle(
        "H1", parent=styles["Heading1"], fontName="Helvetica-Bold", fontSize=17,
        leading=20, textColor=NAVY, spaceBefore=3, spaceAfter=9,
    )
    h2 = ParagraphStyle(
        "H2", parent=styles["Heading2"], fontName="Helvetica-Bold", fontSize=11.5,
        leading=14, textColor=BLUE, spaceBefore=7, spaceAfter=4,
    )
    caption = ParagraphStyle(
        "Caption", parent=small, textColor=colors.HexColor("#52616B"),
        alignment=TA_CENTER, spaceBefore=3,
    )
    cover_title = ParagraphStyle(
        "CoverTitle", parent=h1, fontSize=25, leading=29, textColor=colors.white,
        alignment=TA_LEFT, spaceAfter=14,
    )
    cover_subtitle = ParagraphStyle(
        "CoverSubtitle", parent=body, fontSize=12, leading=16,
        textColor=colors.white,
    )

    doc = SimpleDocTemplate(
        str(OUTPUT), pagesize=letter, rightMargin=0.65 * inch,
        leftMargin=0.65 * inch, topMargin=0.58 * inch,
        bottomMargin=0.62 * inch, title="Satellite Tracking Final Engineering Report",
        author="Satellite Tracking MATLAB Project",
    )
    story = []

    # Page 1 - cover and executive summary.
    cover = Table([[paragraph(
        "Near-Real-Time Satellite Tracking, Orbital Dynamics, and Relativistic Time Dilation",
        cover_title), paragraph(
        "Final engineering report<br/>MATLAB R2026b<br/>Acceptance run: 21 October 2026",
        cover_subtitle)]], colWidths=[4.55 * inch, 1.75 * inch])
    cover.setStyle(TableStyle([
        ("BACKGROUND", (0, 0), (-1, -1), NAVY),
        ("VALIGN", (0, 0), (-1, -1), "MIDDLE"),
        ("LEFTPADDING", (0, 0), (-1, -1), 18),
        ("RIGHTPADDING", (0, 0), (-1, -1), 18),
        ("TOPPADDING", (0, 0), (-1, -1), 22),
        ("BOTTOMPADDING", (0, 0), (-1, -1), 22),
        ("LINEBELOW", (0, 0), (-1, -1), 5, TEAL),
    ]))
    story += [cover, Spacer(1, 0.2 * inch), paragraph("Abstract", h1)]
    story.append(paragraph(
        "This project implements a reproducible MATLAB application for real-record satellite "
        "tracking, orbital-model comparison, and relativistic clock analysis. Six spacecraft "
        "spanning low, medium, and geosynchronous Earth orbit were propagated with the "
        "Vallado/CelesTrak SGP4 implementation and compared with a custom ode45 point-mass "
        "two-body model over 1, 6, and 24 hours. Position differences were transformed to "
        "radial, along-track, and cross-track coordinates. A weak-field clock model produced "
        "+38.452079 microseconds/day for a theoretical GPS orbit relative to an idealized "
        "stationary equatorial surface clock. Final verification completed 120/120 simulations "
        "and passed 17/17 consolidated checks.", body))
    story.append(paragraph("Executive results", h2))
    story.append(metric_table([
        ["Metric", "Measured result"],
        ["Real spacecraft / orbital regimes", "6 / LEO, MEO, GEO"],
        ["Simulation campaign", "120/120 passed"],
        ["Final verification", "17/17 passed"],
        ["Maximum two-body - SGP4 separation", "1,781.797863 km"],
        ["Maximum relative energy drift", "6.0711e-10"],
        ["GPS net relativistic correction", "+38.452079 us/day"],
    ]))
    story.append(paragraph(
        "Interpretation rule: two-body - SGP4 separation is model disagreement, not "
        "independently validated tracking error.", small))

    # Page 2 - objectives and architecture.
    story += [PageBreak(), paragraph("1. Objectives and application architecture", h1)]
    story.append(paragraph(
        "The engineering objective was to connect real orbital records to physics, numerical "
        "analysis, verification evidence, and an interactive display. The completed catalog "
        "contains ISS (ZARYA), NAVSTAR 48, NAVSTAR 51, NOAA-20, Landsat 9, and GOES-16. "
        "The acceptance run uses cached records from 18-19 October 2026 for reproducibility; "
        "the cache is evidence, not a current operational ephemeris.", body))
    story.append(paragraph("Data and computation flow", h2))
    flow = Table([
        ["1. Ingest", "2. Propagate", "3. Compare", "4. Present"],
        ["CelesTrak OMM/TLE\nvalidation and cache", "SGP4 TEME states\n+ ode45 two-body", "J2000/FK5 and RTN\nmetrics", "CSV/MAT, figures,\ndashboard, 3-D globe"],
    ], colWidths=[1.58 * inch] * 4)
    flow.setStyle(TableStyle([
        ("BACKGROUND", (0, 0), (-1, 0), BLUE),
        ("TEXTCOLOR", (0, 0), (-1, 0), colors.white),
        ("BACKGROUND", (0, 1), (-1, 1), LIGHT),
        ("FONTNAME", (0, 0), (-1, 0), "Helvetica-Bold"),
        ("FONTNAME", (0, 1), (-1, 1), "Helvetica"),
        ("FONTSIZE", (0, 0), (-1, -1), 8),
        ("ALIGN", (0, 0), (-1, -1), "CENTER"),
        ("VALIGN", (0, 0), (-1, -1), "MIDDLE"),
        ("GRID", (0, 0), (-1, -1), 0.5, colors.white),
        ("TOPPADDING", (0, 0), (-1, -1), 8),
        ("BOTTOMPADDING", (0, 0), (-1, -1), 8),
    ]))
    story += [flow, Spacer(1, 8), paragraph("Software organization", h2)]
    story.append(metric_table([
        ["Module", "Responsibility"],
        ["src/io", "Provider queries, validation, cache provenance, EOP loading"],
        ["src/propagation", "Vallado SGP4 catalog propagation and ode45 interface"],
        ["src/frames", "TEME to J2000/FK5 conversion"],
        ["src/analysis", "Orbital elements, RTN, diagnostics, campaign metrics"],
        ["src/relativity", "Kinematic, gravitational, and combined clock models"],
        ["src/dashboard + apps", "Verified-state selection, plotting, and export"],
        ["tests + scripts", "Reproducible workflows and acceptance checks"],
    ], widths=(1.65 * inch, 4.55 * inch)))
    story.append(paragraph(
        "The dashboard reads the same saved SGP4/J2000 arrays and Day 9 timing results used "
        "by the analysis. It does not substitute display-only trajectories. A separate control "
        "opens the native satelliteScenario globe when Satellite Communications Toolbox is "
        "installed.", body))

    # Page 3 - foundations.
    story += [PageBreak(), paragraph("2. Mathematical foundations", h1)]
    story.append(paragraph("Two-body dynamics", h2))
    story.append(paragraph(
        "The numerical model integrates r_ddot = -mu r / |r|^3 in a consistent kilometre-"
        "second unit system. Independent circular benchmarks are v_c = sqrt(mu/r) and "
        "T = 2 pi sqrt(r^3/mu). Elliptical apsides are r_p = a(1-e) and r_a = a(1+e). "
        "Specific energy epsilon = v^2/2 - mu/r and specific angular momentum h = r x v "
        "are invariants of the continuous point-mass model and therefore support numerical "
        "verification.", body))
    story.append(paragraph("SGP4 and frame discipline", h2))
    story.append(paragraph(
        "SGP4 returns states in the True Equator, Mean Equinox frame. Direct subtraction from "
        "an arbitrary ECI state would mix frame effects with dynamics. Each SGP4 history is "
        "therefore converted through the documented Vallado IAU-76/FK5 path using CelesTrak "
        "Earth-orientation data. The first converted J2000/FK5 state initializes ode45. The "
        "difference is defined as two-body minus SGP4 and projected into the SGP4 radial, "
        "along-track, and cross-track basis.", body))
    story.append(paragraph("Relativistic timing", h2))
    story.append(paragraph(
        "The sign convention is satellite proper time minus reference-clock proper time. The "
        "reference is an idealized stationary clock at the WGS-84 equatorial radius in a "
        "spherical, nonrotating Earth model. The leading rates are:<br/><br/>"
        "gravitational: delta rate = (mu/c^2)(1/R_E - 1/r)<br/>"
        "kinematic: delta rate = -v^2/(2c^2)<br/><br/>"
        "Rates are integrated with respect to elapsed coordinate time and reported in "
        "microseconds per day. The reference convention is essential: the familiar GPS "
        "+38.5 microseconds/day value is not independent of the chosen clock and coordinate "
        "definition.", body))
    story.append(paragraph("Model boundaries", h2))
    story.append(metric_table([
        ["Included", "Excluded"],
        ["SGP4 mean-element propagation", "Independent precision truth ephemeris"],
        ["Point-mass two-body ode45 model", "J2, drag, third bodies, SRP, maneuvers"],
        ["TEME to J2000/FK5 conversion", "Full IAU 2006/2000A reduction"],
        ["First-order gravity + special relativity", "Rotation, tides, signal path, GPS system time"],
    ], widths=(3.1 * inch, 3.1 * inch)))

    # Page 4 - verification.
    story += [PageBreak(), paragraph("3. Verification and numerical campaign", h1)]
    story.append(paragraph(
        "The deterministic campaign spans five semimajor-axis regimes, four eccentricities, "
        "and six inclinations for 120 full-orbit cases. Each case contains 181 requested output "
        "samples. A case passes only when all states are finite, relative energy and angular-"
        "momentum drift remain below 1e-7, and numerical perigee and apogee agree with the "
        "analytical values within 0.25 km.", body))
    story.append(metric_table([
        ["Verification item", "Measured / criterion"],
        ["Automated orbit simulations", "120 passed / at least 100"],
        ["Circular-period closure", "2.645e-10 km / 0.01 km"],
        ["Maximum relative energy drift", "6.0711e-10 / 1e-7"],
        ["Maximum relative angular-momentum drift", "3.0380e-10 / 1e-7"],
        ["TEME-J2000 rotation orthogonality", "5.088e-16 / 1e-10"],
        ["RTN reconstruction closure", "9.444e-13 km / 1e-9 km"],
        ["Tightest 6-hour convergence difference", "0.0001157 m / 10 m"],
        ["Consolidated acceptance checks", "17 passed, 0 failed, 0 skipped"],
    ]))
    story.append(Spacer(1, 8))
    story.append(report_image("final_04_solver_convergence.png", 5.65 * inch, 3.75 * inch))
    story.append(paragraph(
        "Figure 1. ode45 numerical convergence against a tighter two-body solution. This "
        "demonstrates numerical convergence of the implementation, not real-world orbit "
        "prediction accuracy.", caption))

    # Page 5 - comparison results.
    story += [PageBreak(), paragraph("4. Orbital-model comparison results", h1)]
    story.append(report_image("final_02_sgp4_two_body_separation.png", 6.35 * inch, 3.85 * inch))
    story.append(paragraph(
        "Figure 2. Magnitude of two-body minus SGP4 position separation for six real records.",
        caption))
    story.append(Spacer(1, 4))
    story.append(metric_table([
        ["Prediction horizon", "Maximum separation", "Mean case RMS"],
        ["1 hour", "95.91 km", "16.31 km"],
        ["6 hours", "466.12 km", "100.78 km"],
        ["24 hours", "1,781.80 km", "404.87 km"],
    ], widths=(2.1 * inch, 2.05 * inch, 2.05 * inch)))
    story.append(paragraph(
        "The global RMS separation across all stored samples is 575.823254 km. Landsat 9 "
        "produced the largest 24-hour separation, with a 1,765.071 km maximum absolute "
        "along-track component and a 240.977 km radial component. The trend is expected: the "
        "two-body model omits drag, oblateness, higher geopotential terms, lunisolar gravity, "
        "solar radiation pressure, and maneuver representation. LEO phase is particularly "
        "sensitive to small mean-motion differences. No independent truth ephemeris was used, "
        "so the result must remain labeled model disagreement.", body))

    # Page 6 - timing and application performance.
    story += [PageBreak(), paragraph("5. Relativistic timing and application performance", h1)]
    story.append(report_image("final_06_relativistic_clock_drift.png", 6.25 * inch, 4.15 * inch))
    story.append(paragraph(
        "Figure 3. Gravitational, kinematic, and net clock drift for idealized circular orbits "
        "relative to a stationary equatorial surface clock.", caption))
    story.append(metric_table([
        ["Timing / application metric", "Measured result"],
        ["GPS gravitational contribution", "+45.660757 us/day"],
        ["GPS kinematic contribution", "-7.208677 us/day"],
        ["GPS net contribution", "+38.452079 us/day"],
        ["Difference from +38.5 benchmark", "0.047921 us/day (0.1245%)"],
        ["Idealized zero-drift crossover", "3,189.069 km altitude"],
        ["Dashboard snapshot update latency", "0.884 ms mean over 100 calls"],
        ["Cold hidden-UI startup", "20.166 s on acceptance machine"],
    ]))
    story.append(paragraph(
        "ISS is kinematically dominated and accumulates approximately -24.48 us/day in this "
        "convention. Real GPS records are near +38.44 us/day, while GOES-16 is approximately "
        "+46.45 us/day. Startup includes MATLAB graphics initialization and should not be "
        "generalized to warm sessions or different hardware.", small))

    # Page 7 - limitations and conclusions.
    story += [PageBreak(), paragraph("6. Limitations, conclusions, and next steps", h1)]
    story.append(paragraph("Acceptance limitations", h2))
    limitations = [
        "Cached element epochs are reproducible evidence, not current operational tracking data.",
        "SGP4 output is not a precision truth ephemeris, and no surveyed truth trajectory was used.",
        "The two-body model intentionally omits major perturbations and orbit-determination uncertainty.",
        "The clock model excludes Earth rotation, geopotential harmonics, tides, signal delays, and operational GPS time realization.",
        "A clean MATLAB installation without Satellite Communications Toolbox was unavailable; missing-toolbox behavior is not tested.",
        "Hidden dashboard startup and data integrity were automated; interactive close behavior was not manually tested in the headless run.",
    ]
    for item in limitations:
        story.append(paragraph(f"- {item}", body))
    story.append(paragraph("Conclusions", h2))
    story.append(paragraph(
        "The project meets its central portfolio objectives: real orbital data, validated SGP4 "
        "execution, independent ode45 propagation, frame-consistent RTN analysis, special and "
        "gravitational relativity, more than 100 automated runs, more than 10 final checks, "
        "exported evidence, and an interactive dashboard. The verification supports numerical "
        "and software correctness within the tested scope without overstating model agreement "
        "as operational tracking accuracy.", body))
    story.append(paragraph("Recommended extensions", h2))
    story.append(paragraph(
        "Add explicit orbital-record age alarms; compare against an independent precision "
        "ephemeris; implement J2, drag, lunisolar gravity, and covariance propagation; add "
        "ground-station access and link analysis; and package the programmatic dashboard as an "
        "App Designer application after manual cross-platform testing.", body))
    story.append(paragraph("References", h2))
    references = [
        "1. Vallado, D. A., Fundamentals of Astrodynamics and Applications.",
        "2. Vallado, Crawford, Hujsak, and Kelso, Revisiting Spacetrack Report #3, AIAA 2006-6753.",
        "3. CelesTrak, General Perturbations data and SGP4 reference implementation.",
        "4. MathWorks, MATLAB ode45, satelliteScenario, and Satellite Communications Toolbox documentation.",
        "5. Ashby, N., Relativity in the Global Positioning System, Living Reviews in Relativity.",
    ]
    for item in references:
        story.append(paragraph(item, small))

    doc.build(story, onFirstPage=page_header_footer, onLaterPages=page_header_footer)
    print(OUTPUT)


if __name__ == "__main__":
    build_report()
