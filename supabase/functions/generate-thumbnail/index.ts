import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import {
  ImageMagick,
  initializeImageMagick,
  MagickFormat,
} from "npm:@imagemagick/magick-wasm@0.0.30";
import { createClient } from "npm:@supabase/supabase-js@2";

// Initialize ImageMagick WASM
const wasmBytes = await Deno.readFile(
  new URL(
    "magick.wasm",
    import.meta.resolve("npm:@imagemagick/magick-wasm@0.0.30")
  )
);
await initializeImageMagick(wasmBytes);

const THUMBNAIL_SIZE = 300;
const BUCKET_NAME = "cockat-images";

Deno.serve(async (req) => {
  try {
    // CORS headers
    if (req.method === "OPTIONS") {
      return new Response(null, {
        headers: {
          "Access-Control-Allow-Origin": "*",
          "Access-Control-Allow-Methods": "POST, OPTIONS",
          "Access-Control-Allow-Headers": "Content-Type, Authorization",
        },
      });
    }

    const { category, id, updateDb = true } = await req.json();

    if (!category || !id) {
      return new Response(
        JSON.stringify({ error: "category and id are required" }),
        { status: 400, headers: { "Content-Type": "application/json" } }
      );
    }

    // Initialize Supabase client with service role
    const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
    const supabaseServiceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
    const supabase = createClient(supabaseUrl, supabaseServiceKey);

    // Download original image - try multiple extensions
    let imageBytes: Uint8Array | null = null;

    for (const ext of ["png", "jpg", "jpeg", "webp"]) {
      const path = `${category}/originals/${id}.${ext}`;
      const { data, error } = await supabase.storage
        .from(BUCKET_NAME)
        .download(path);

      if (!error && data) {
        const arrayBuffer = await data.arrayBuffer();
        imageBytes = new Uint8Array(arrayBuffer);
        console.log(`Found image at: ${path}`);
        break;
      }
    }

    if (!imageBytes) {
      return new Response(
        JSON.stringify({ error: "Image not found in any supported format" }),
        { status: 404, headers: { "Content-Type": "application/json" } }
      );
    }

    // Process image with ImageMagick
    const thumbnailBytes = ImageMagick.read(imageBytes, (img) => {
      // Resize to thumbnail size (maintain aspect ratio)
      const width = img.width;
      const height = img.height;

      let newWidth = THUMBNAIL_SIZE;
      let newHeight = THUMBNAIL_SIZE;

      if (width > height) {
        newHeight = Math.round((height / width) * THUMBNAIL_SIZE);
      } else {
        newWidth = Math.round((width / height) * THUMBNAIL_SIZE);
      }

      img.resize(newWidth, newHeight);
      img.quality = 80;

      // Write as PNG (more compatible)
      return img.write(MagickFormat.Png, (data) => data);
    });

    // Upload thumbnail
    const thumbnailPath = `${category}/thumbnails/${id}.png`;
    const { error: uploadError } = await supabase.storage
      .from(BUCKET_NAME)
      .upload(thumbnailPath, thumbnailBytes, {
        contentType: "image/png",
        upsert: true,
      });

    if (uploadError) {
      return new Response(
        JSON.stringify({ error: `Upload failed: ${uploadError.message}` }),
        { status: 500, headers: { "Content-Type": "application/json" } }
      );
    }

    // Get public URL
    const { data: urlData } = supabase.storage
      .from(BUCKET_NAME)
      .getPublicUrl(thumbnailPath);

    const thumbnailUrl = urlData.publicUrl;

    // Update database if requested
    if (updateDb) {
      const tableName = category === "products" ? "products" :
                        category === "cocktails" ? "cocktails" :
                        category === "ingredients" ? "ingredients" :
                        category === "misc-items" ? "misc_items" : null;

      if (tableName) {
        const { error: dbError } = await supabase
          .from(tableName)
          .update({ thumbnail_url: thumbnailUrl, updated_at: new Date().toISOString() })
          .eq("id", id);

        if (dbError) {
          console.error("DB update error:", dbError);
        }
      }
    }

    return new Response(
      JSON.stringify({
        success: true,
        thumbnailUrl,
        path: thumbnailPath,
      }),
      {
        headers: {
          "Content-Type": "application/json",
          "Access-Control-Allow-Origin": "*",
        },
      }
    );

  } catch (error) {
    console.error("Error:", error);
    return new Response(
      JSON.stringify({ error: error.message || String(error) }),
      { status: 500, headers: { "Content-Type": "application/json" } }
    );
  }
});
